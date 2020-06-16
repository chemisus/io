#!/usr/bin/env python

import sys
import json


class IO:
    @staticmethod
    def main():
        [plugin.enable() for plugin in PLUGINS]

        reader_name = sys.argv[1]
        writer_name = sys.argv[2]

        stream = sys.stdin
        reader = READERS[reader_name]()
        writer = WRITERS[writer_name]()

        IO(stream, reader, writer).transform()

    def __init__(self, stream, reader, writer):
        self.stream = stream
        self.reader = reader
        self.writer = writer

    def transform(self):
        for line in self.stream:
            line = line.strip("\n")
            if len(line):
                self.reader.read(line, self.writer)


class Plugin:
    def enable(self):
        pass

    def disable(self):
        pass


class Writer:
    def write(self, keys: [str], values: [str]):
        pass


class Reader:
    def read(self, line: str, writer: Writer):
        pass


class TSVReader(Reader):
    keys = None

    def read(self, line: str, writer: Writer):
        values = line.split("\t")
        if self.keys is None:
            self.keys = values
        else:
            writer.write(self.keys, values)


class CSVReader(Reader):
    keys = None

    def read(self, line: str, writer: Writer):
        values = line.split(",")
        if self.keys is None:
            self.keys = values
        else:
            writer.write(self.keys, values)


class JSONReader(Reader):
    keys = None

    def read(self, line: str, writer: Writer):
        value = json.loads(line)

        if self.keys is None:
            self.keys = value.keys()

        values = [value.get(key) for key in self.keys]
        writer.write(self.keys, values)


class TSVWriter(Writer):
    keys = None

    def write(self, keys: [str], values: [str]):
        if self.keys is None:
            self.keys = keys
            for key in self.keys:
                print(json.dumps(key), end="")
                print("\t", end="")

        print("")
        for value in values:
            print(json.dumps(value), end="")
            print("\t", end="")


class CSVWriter(Writer):
    keys = None

    def write(self, keys: [str], values: [str]):
        if self.keys is None:
            self.keys = keys
            for key in self.keys:
                print(json.dumps(key), end="")
                print(",", end="")

        print("")
        for value in values:
            print(json.dumps(value), end="")
            print(",", end="")


class JSONWriter(Writer):
    def write(self, keys: [str], values: [str]):
        print(json.dumps(dict(zip(keys, values))))


class JSONPlugin(Plugin):
    name = "json"
    reader = JSONReader
    writer = JSONWriter

    def enable(self):
        READERS[self.name] = self.reader
        WRITERS[self.name] = self.writer

    def disable(self):
        del READERS[self.name]
        del WRITERS[self.name]


class TSVPlugin(Plugin):
    name = "tsv"
    reader = TSVReader
    writer = TSVWriter

    def enable(self):
        READERS[self.name] = self.reader
        WRITERS[self.name] = self.writer

    def disable(self):
        del READERS[self.name]
        del WRITERS[self.name]


class CSVPlugin(Plugin):
    name = "csv"
    reader = CSVReader
    writer = CSVWriter

    def enable(self):
        READERS[self.name] = self.reader
        WRITERS[self.name] = self.writer

    def disable(self):
        del READERS[self.name]
        del WRITERS[self.name]


PLUGINS = []

PLUGINS.append(JSONPlugin())
PLUGINS.append(TSVPlugin())
PLUGINS.append(CSVPlugin())

READERS = {
}

WRITERS = {
}

if __name__ == "__main__":
    IO.main()
