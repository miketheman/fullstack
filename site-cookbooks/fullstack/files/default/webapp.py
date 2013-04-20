#!/usr/bin/env python
'''
This application is a simple implemnetation of a word counter.
It leverages the bottle micro-framework, as well as pymongo.
'''

import time
from functools import wraps
from bottle import route, run, response, request
from bson.json_util import default
import pymongo
from pymongo.uri_parser import parse_uri
import json
from statsd import statsd

try:
    import local_settings as config
except ImportError:
    # make default config: non-replset connection
    # directly to mongo on localhost
    class config(object):
        mongo_uri = 'mongodb://localhost'

mongo_uri = getattr(config, 'mongo_uri', 'mongodb://localhost')
uri_components = parse_uri(mongo_uri)
if 'replicaSet' in uri_components['options']:
    conn = pymongo.ReplicaSetConnection(mongo_uri)
else:
    conn = pymongo.Connection(mongo_uri)

db = conn.test

@route('/insert/:name')
@statsd.timed('fullstack.insert.time', sample_rate=0.5)
def insert(name):
    doc = {'name': name}
    db.phrases.update(doc, {"$inc":{"count": 1}}, upsert=True)

    # TODO: Figure out a better place for this - some sort of setup url?
    db.phrases.ensure_index('name')
    db.phrases.ensure_index('count')

    return json.dumps(doc, default=default)


@route('/get')
@route('/get/:name')
@statsd.timed('fullstack.get.time', sample_rate=0.5)
def get(name=None):
    query = {}
    if name is not None:
        query['name'] = name

    response.set_header('Content-Type', 'application/json')
    return json.dumps(list(db.phrases.find(query)), default=default)

@route('/toplist')
@statsd.timed('fullstack.toplist.time', sample_rate=0.5)
def toplist(name=None):

    # TODO: Figure out a better place for this - some sort of setup url?
    db.phrases.ensure_index('name')
    db.phrases.ensure_index('count')

    query = db.phrases.find({}, ['count', 'name']).sort('count', -1).limit(10)
    
    response.set_header('Content-Type', 'application/json')
    return json.dumps(list(query), default=default)


# This is because I hate seeing errors for no reason.
@route('/favicon.ico')
def favicon():
    return

if __name__ == '__main__':
    run(host='localhost', port=8080, reloader=True)