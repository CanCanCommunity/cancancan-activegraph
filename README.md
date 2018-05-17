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
can :read, Article, author: { id: user.id }
```

Here `id` is a property on `Author` and `Article` has `has_one` relation with `Author`.

```ruby
can :read, User, friends: { rel_length: {min: 1, max: 2} id: user.id }
```

Here all the one and two level deep friends of the user will be accessible.

```ruby
can :read, User, friends: false
```

Here all the users who don't have friends will be returned.
Check on specs for more usage.