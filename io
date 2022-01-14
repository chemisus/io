#!/usr/bin/env python
from abc import abstractmethod
from functools import wraps
from typing import Iterable, Tuple, List

import click
import logging
import csv
import json

logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.DEBUG)


class IO:
    reader = None
    writer = None

    def write(self, input):
        entries = self.reader.read(input)
        for line in self.writer.write(entries):
            print(line)


class Reader:
    @abstractmethod
    def read(self, input: Iterable[str]) -> Iterable[Tuple[List[str], List[str]]]:
        pass


class Writer:
    @abstractmethod
    def write(self, entries: Iterable[Tuple[List[str], List[str]]]) -> Iterable[str]:
        pass


class DelimitedReader(Reader):
    def __init__(self, delimiter: str, quote_character: str):
        self.delimiter = delimiter
        self.quote_character = quote_character

    def read(self, input: Iterable[str]) -> Iterable[Tuple[List[str], List[str]]]:
        reader = csv.reader(input, delimiter=self.delimiter, quotechar=self.quote_character)
        keys = None
        for row in reader:
            if keys is None:
                keys = row
                continue

            yield keys, row


class DelimitedWriter(Writer):
    def __init__(self, delimiter: str, quote_character: str, force_quote: bool):
        self.delimiter = delimiter
        self.quote_character = quote_character
        self.force_quote = force_quote

    def quote(self, value) -> str:
        value = str(value).replace(self.quote_character, self.quote_character + self.quote_character)

        if self.force_quote or self.delimiter in value:
            value = self.quote_character + value + self.quote_character

        return value

    def write(self, entries: Iterable[Tuple[List[str], List[str]]]) -> Iterable[str]:
        keyed = False
        for keys, values in entries:
            if not keyed:
                keyed = True
                yield self.delimiter.join([self.quote(it) for it in keys])

            yield self.delimiter.join([self.quote(it) for it in values])


class CSV:
    DELIMITER = ','
    QUOTE_CHARACTER = '"'
    FORCE_QUOTE = False


class TSV:
    DELIMITER = '\t'
    QUOTE_CHARACTER = '"'
    FORCE_QUOTE = False


class SSV:
    DELIMITER = ' '
    QUOTE_CHARACTER = '"'
    FORCE_QUOTE = False


class JSONReader(Reader):
    def read(self, input) -> Iterable[Tuple[List[str], List[str]]]:
        keys = None
        for line in input:
            data = json.loads(line)
            if keys is None:
                keys = list(data.keys())
            values = [data[it] for it in keys]
            yield keys, values


class JSONWriter(Writer):
    def __init__(self, indent=0):
        self.indent = indent

    def write(self, entries: Iterable[Tuple[List[str], List[str]]]) -> Iterable[str]:
        for keys, values in entries:
            data = {keys[i]: values[i] for i in range(0, len(keys))}
            yield json.dumps(data, indent=self.indent if self.indent else None)


@click.group()
@click.pass_context
def io(context):
    context.obj = IO()


def make_readers():
    def make_delimiter_reader(name: str, delimiter: str, quote_character: str):
        @io.group(name=name)
        @click.option('-d', 'delimiter', default=delimiter)
        @click.option('-c', 'quote_character', default=quote_character)
        @click.pass_obj
        def delimiter_reader(io, delimiter, quote_character):
            io.reader = DelimitedReader(delimiter, quote_character)

        return delimiter_reader

    yield make_delimiter_reader("csv", CSV.DELIMITER, CSV.QUOTE_CHARACTER)
    yield make_delimiter_reader("tsv", TSV.DELIMITER, TSV.QUOTE_CHARACTER)
    yield make_delimiter_reader("ssv", SSV.DELIMITER, SSV.QUOTE_CHARACTER)

    @io.group()
    @click.pass_obj
    def json(io):
        io.reader = JSONReader()

    yield json


def make_writers(reader):
    def writer(writer):
        @click.pass_obj
        @wraps(writer)
        def wrapper(io: IO, inputs, *args, **kwargs):
            writer(io, inputs, *args, **kwargs)
            for input in inputs:
                io.write(input)

        return wrapper

    def make_delimiter_writer(name: str, delimiter: str, quote_character: str, force_quote: bool):
        @reader.command(name=name)
        @click.argument('inputs', type=click.File('r'), nargs=-1)
        @click.option('-d', 'delimiter', default=delimiter)
        @click.option('-c', 'quote_character', default=quote_character)
        @click.option('-f', '--force-quote/--no-force-quote', 'force_quote', default=force_quote)
        @writer
        def delimiter_writer(io, inputs, delimiter, quote_character, force_quote):
            io.writer = DelimitedWriter(delimiter, quote_character, force_quote)

        return delimiter_writer

    make_delimiter_writer("csv", CSV.DELIMITER, CSV.QUOTE_CHARACTER, CSV.FORCE_QUOTE)
    make_delimiter_writer("tsv", TSV.DELIMITER, TSV.QUOTE_CHARACTER, TSV.FORCE_QUOTE)
    make_delimiter_writer("ssv", SSV.DELIMITER, SSV.QUOTE_CHARACTER, SSV.FORCE_QUOTE)

    @reader.command()
    @click.argument('inputs', type=click.File('r'), nargs=-1)
    @click.option('-i', '--indent', 'indent', type=int, default=0)
    @writer
    def json(io, inputs, indent):
        io.writer = JSONWriter(indent)


if __name__ == '__main__':
    for reader in make_readers():
        make_writers(reader)

    io()
