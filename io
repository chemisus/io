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
    def __init__(self, delimiter: str = ",", quotechar: str = '"'):
        self.delimiter = delimiter
        self.quotechar = quotechar

    def read(self, input: Iterable[str]) -> Iterable[Tuple[List[str], List[str]]]:
        reader = csv.reader(input, delimiter=self.delimiter, quotechar=self.quotechar)
        keys = None
        for row in reader:
            if keys is None:
                keys = row
                continue

            yield keys, row


class DelimitedWriter(Writer):
    def __init__(self, delimiter: str = ",", quotechar: str = '"', forcequote=False):
        self.delimiter = delimiter
        self.quotechar = quotechar
        self.forcequote = forcequote

    def quote(self, value) -> str:
        value = str(value).replace(self.quotechar, self.quotechar + self.quotechar)

        if self.forcequote or self.delimiter in value:
            value = self.quotechar + value + self.quotechar

        return value

    def write(self, entries: Iterable[Tuple[List[str], List[str]]]) -> Iterable[str]:
        keyed = False
        for keys, values in entries:
            if not keyed:
                yield self.delimiter.join([self.quote(it) for it in keys])

            yield self.delimiter.join([self.quote(it) for it in values])


class CSV:
    DELIMITER = ','
    QUOTECHAR = '"'


class TSV:
    DELIMITER = '\t'
    QUOTECHAR = '"'


class SSV:
    DELIMITER = ' '
    QUOTECHAR = '"'


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
    @io.group()
    @click.option('-d', 'delimiter', default=CSV.DELIMITER)
    @click.option('-c', 'quotechar', default=CSV.QUOTECHAR)
    @click.pass_obj
    def csv(io, delimiter, quotechar):
        io.reader = DelimitedReader(delimiter, quotechar)

    yield csv

    @io.group()
    @click.option('-d', 'delimiter', default=TSV.DELIMITER)
    @click.option('-c', 'quotechar', default=TSV.QUOTECHAR)
    @click.pass_obj
    def tsv(io, delimiter, quotechar):
        io.reader = DelimitedReader(delimiter, quotechar)

    yield tsv

    @io.group()
    @click.option('-d', 'delimiter', default=SSV.DELIMITER)
    @click.option('-c', 'quotechar', default=SSV.QUOTECHAR)
    @click.pass_obj
    def ssv(io, delimiter, quotechar):
        io.reader = DelimitedReader(delimiter, quotechar)

    yield ssv

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

    @reader.command()
    @click.argument('inputs', type=click.File('r'), nargs=-1)
    @click.option('-d', 'delimiter', default=CSV.DELIMITER)
    @click.option('-c', 'quotechar', default=CSV.QUOTECHAR)
    @writer
    def csv(io, inputs, delimiter, quotechar):
        io.writer = DelimitedWriter(delimiter, quotechar)

    @reader.command()
    @click.argument('inputs', type=click.File('r'), nargs=-1)
    @click.option('-d', 'delimiter', default=TSV.DELIMITER)
    @click.option('-c', 'quotechar', default=TSV.QUOTECHAR)
    @writer
    def tsv(io, inputs, delimiter, quotechar):
        io.writer = DelimitedWriter(delimiter, quotechar)

    @reader.command()
    @click.argument('inputs', type=click.File('r'), nargs=-1)
    @click.option('-d', 'delimiter', default=SSV.DELIMITER)
    @click.option('-c', 'quotechar', default=SSV.QUOTECHAR)
    @writer
    def ssv(io, inputs, delimiter, quotechar):
        io.writer = DelimitedWriter(delimiter, quotechar)

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
