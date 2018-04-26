# CanCanCan-Neo4j

This is the adapter for the [CanCanCan](https://github.com/CanCanCommunity/cancancan) authorization
library to automatically generate Cypher queries from ability rules. It returns QueryProxy object for resources.

Adds support for neo4j >= 9.0 and cancancan <= 2.1.4

## Ruby Versions Supported

Ruby >= 2.0.0

## Usage

In your `Gemfile`, insert the following line:

```ruby
gem 'cancancan-neo4j'
```

```ruby
can :read, Article, author: { name: 'Chunky' }
```

Here name is a property on Author and Article has 'has_one' relation with Author.
