#!/usr/bin/env python
from functools import wraps

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
        for keys, values in self.reader.read(input):
            for data in self.writer.write(keys, values):
                print(data)


class CSVReader:
    def __init__(self, delimiter=",", quotechar='"'):
        self.delimiter = delimiter
        self.quotechar = quotechar

    def read(self, input):
        reader = csv.reader(input, delimiter=self.delimiter, quotechar=self.quotechar)
        keys = None
        for row in reader:
            if keys is None:
                keys = row
                continue

            yield keys, row


class CSVWriter:
    def write(self, keys, values):
        if False:
            yield {}


class JSONReader:
    def read(self, input):
        pass


class JSONWriter:
    def __init__(self, indent=0):
        self.indent = indent

    def write(self, keys, values):
        data = {}
        for i in range(0, len(keys)):
            data[keys[i]] = values[i]
        yield json.dumps(data, indent=self.indent if self.indent else None)


@click.group()
@click.pass_context
def io(context):
    logger.info("io")
    context.obj = IO()


def make_readers():
    @io.group()
    @click.option('-d', 'separator', default=',')
    @click.pass_obj
    def csv(io, separator):
        logger.info("csv reader")
        io.reader = CSVReader()

    yield csv

    @io.group()
    @click.pass_obj
    def json(io):
        logger.info("json reader")
        io.reader = JSONWriter()

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
    @click.option('-d', 'separator', default=',')
    @writer
    def csv(io, inputs, separator):
        logger.info("csv writer")
        io.writer = CSVWriter()

    @reader.command()
    @click.argument('inputs', type=click.File('r'), nargs=-1)
    @click.option('-i', '--indent', 'indent', type=int, default=0)
    @writer
    def json(io, inputs, indent):
        logger.info("json writer")
        io.writer = JSONWriter(indent)


if __name__ == '__main__':
    for reader in make_readers():
        make_writers(reader)

    io()
