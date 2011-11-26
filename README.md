redisarray
==========

[RedisArray] Implements memory efficient algorithm allowing to store tables or two dimensional arrays inside Redis.

Introduction
============

Often we need to store a table with headers and rows or just an adjacent 2D array inside our Redis key-value store. We could quickly design our own custom solution but it probably would not be optimized for memory usage.
The purpose of this project is to design general solution for storing two dimensional arrays inside Redis with memory optimization in mind. 
How is that accomplished? All the data that is going to be written is just sliced on pieces behind the scenes and stored in hashes with 100 of fields each which is memory efficient. To read more about this technique follow this page: http://redis.io/topics/memory-optimization


Compatibility
=============

Ruby 1.8.7, 1.9.2 and 1.9.3
	
Install
=======

    gem install redisarray

Terminology
===========

1. A table is just 2 dimensional array so the RedisTable class would represent a single 2 dimensional array (if it would be instantiated).
	An example of 2 dim array: 
	- [ ['row 1 cell 1','row 1 cell 2'], ['row 2 cell 1','row 2 cell 2'] ]
2. A sheet is the same as a table but used in a context of a workbook.
3. A workbook is a container for sheets (2 dimensional array) so we can say it is the same as 3 dimensional array.
	An example of 3 dim array: 
	- [ [ ['r1c1','r1c2], ['r2c1','r2c2] ], [ ['r1c1','r1c2], ['r2c1','r2c2] ] ]

Usage
=====

I will add some syntactic sugar for class names in the next release.
For now there are these classes:

1. RedisTable - where most of the action takes place, this class is not going to be instantiated, instead we should use it like this: RedisTable.set_table_data
2. RedisWorkbook - a wrapper around RedisTable that simplifies storage of 3 dim arrays or in other words an array of worksheets with optional headers 
3. RedisHashGroup - used as a namespace so that we can store workbooks (or 3D arrays) with the same name side by side. 
	You can use it like this:
	* RedisHashGroup.new.name - this will generate random namespace that does not exist in Redis yet 
	* RedisHashGroup.new(:prefix => 'my_prefix_').name - the same as above but the namespace will include the prefix

You can start using redisarray gem like this:

	require 'rubygems'
	require 'redisarray'
	include RedisArray

	group_name = RedisHashGroup.new.name
    @workbook = RedisWorkbook.new group_name, 'my_workbook'
	@workbook.set_sheet_data "my_sheet_name",
                               rows = [['row 1 cell 1','row 1 cell 2'], ['row 2 cell 1','row 2 cell 2']],
                               :start_from_row => 3
	p @workbook.get_sheet_data("my_sheet_name")	

By default it will assume redis is listening on localhost port 6379, to change it do this:

	require 'rubygems'
	require 'redisarray'
	require 'redis'
	include RedisArray
	
	RedisTable.set_redis Redis.new(:host => 'localhost', :port => 6379)
	
	group_name = RedisHashGroup.new.name
	...
	
For more examples take a look at spec directory especially in redis_workbook_spec.rb 

Developer Instructions
======================

The dependencies for the gem and for developing the gem are managed by Bundler.

    gem install bundler
    git clone http://github.com/ksob/redisarray.git
    cd ./redisarray
	bundle install

Specs can be run with (they require some preconditions to be met like running Redis on localhost port 6379):

	bundle exec rspec spec

License
=======

(The MIT License)

Copyright (c) 2011 Kamil Sobieraj, ksobej@gmail.com

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.