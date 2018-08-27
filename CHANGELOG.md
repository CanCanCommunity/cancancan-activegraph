# Change Log

## 1.3.2

Optimising cypher for single can rule.
Optimising execution for multiple can rules with one rule with no conditions.

## 1.3.1

Fixing Issue#12 - Authorizing single resource for a scope based rule

## 1.3.0

Removed `active_model` version dependency of `<5.2.0`
Fixed `cancancan` version dependecy of `<=2.1.4`
Fixed Issue #10 - Improved Cypher peroformance

## 1.2.2

Adding label in relation path end node. eg. changing MATCH (article:Article) WHERE (( NOT (article:Article)-[:mention]->()-[:user]->()))' to MATCH (article:Article) WHERE (( NOT (article:Article)-[:mention]->(:Mention)-[:user]->(:User)))'

## 1.2.1

Fixing in case the variable length is specified on association and that association also has asssociation conditions, the variable lenght association condition was not working.

## 1.2.0

Fixing Issue#4 - ability to specify variable length relation in conditions hash of a rule.

## 1.0.3

Fixing Issue#1 - undefined method error on object which does not have relation established, and the can rule containes conditions on that relation.

## 1.0.2

Fixing `cancancan` gem version to `<=2.1.4` as `cancancan-neo4j` gem is not compatible with higher version of  `cancancan`

## 1.0.1

Fixing `activemodel` gem version to `<5.2.0` as `neo4j` gem is not compatible with `activemodel-5.2.0`

## 1.0.0

Initial release.


