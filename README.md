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

Given `Article` has `has_one` relation with `Author`. To give access to all articles which are authored by current users, we can use can rule like following,

```ruby
can :read, Article, author: { id: user.id }
```

To define length of relationship, we can use `rel_legth` on realtionship conditions like bellow.  Here all the one and two level deep friends of the user will be accessible.

```ruby
can :read, User, friends: { rel_length: {min: 1, max: 2}, id: user.id }
```

To check existance or non existance of relationship, we can specify `true` or `false` on relationship like bellow. Here all the users who don't have friends will be returned.

```ruby
can :read, User, friends: false
```

To use scope with a rule, you can do folowing.

```ruby
can :read, User, User.where(active: true)
```

You can use simple rules like `can :read, User` with rule like above, but can not use rules with another scope and hash conditions. The order of rules also matter.

Check on specs for more usage.