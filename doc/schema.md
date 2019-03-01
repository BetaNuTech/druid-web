# BlueSky Data Schema

## ActiveRecord Models

* [Leads](#leads)
* Lead Sources
* Contacts

# Leads

A Lead combines changeable contact information with relationships to Lead
Sources, lead preferences, user assignment, and state.

```
|---------------------+----------+-------+----------|
| Table: leads        |          |       |          |
|---------------------+----------+-------+----------|
|---------------------+----------+-------+----------|
| column name         | type     | notes | required |
|---------------------+----------+-------+----------|
| id                  | uuid     | PK    | Y        |
|---------------------+----------+-------+----------|
| user_id             | uuid     | FK    | N        |
| lead_source_id      | uuid     | FK    | N        |
| title               | string   |       | N        |
| first_name          | string   |       | Y        |
| last_name           | string   |       | N        |
| referral            | string   |       | N        |
| state               | string   |       | Y        |
| notes               | text     |       | N        |
| first_comm          | datetime |       | Y        |
| last_comm           | datetime |       | Y        |
|---------------------+----------+-------+----------|
| created_at          | datetime |       | Y        |
| updated_at          | datetime |       | Y        |
|---------------------+----------+-------+----------|
```

## Lead Relationships

```
has_many: :contacts
belongs_to: :source, class_name: 'LeadSource'
belongs_to: user
has_one: :preference, class_name: 'LeadPreference'
```

## Lead Indexes

TODO:
* user_id, state
* lead_source_id, state
* state, first_comm, last_comm

# Lead Preferences

Lead Preferences record property preferences that a lead may have.

```
|-------------+------------------+-------+----------|
| Table:      | lead_preferences |       |          |
|-------------+------------------+-------+----------|
|-------------+------------------+-------+----------|
| column name | type             | notes | required |
|-------------+------------------+-------+----------|
| id          | uuid             | PK    | Y        |
|-------------+------------------+-------+----------|
| lead_id     | uuid             | FK    | Y        |
| min_area    | integer          |       | N        |
| max_area    | integer          |       | N        |
| min_price   | decimal          |       | N        |
| max_price   | decimal          |       | N        |
| move_in     | datetime         |       | N        |
| baths       | decimal          |       | N        |
| pets        | boolean          |       | N        |
| smoker      | boolean          |       | N        |
| washerdryer | boolean          |       | N        |
| notes       | text             |       | N        |
|-------------+------------------+-------+----------|
| created_at  | datetime         |       | Y        |
| updated_at  | datetime         |       | Y        |
|-------------+------------------+-------+----------|
```

## Relationships

```
belongs_to: :lead
```

## Indexes

TODO
* lead_id

# Lead Sources

Lead Sources identify both the conceptual sources of Leads and drive application logic for processing raw Lead information. See `Leads::Creator` and `Leads::Adapters`


```
|-------------+------------------+-------+----------|
| Table:      | lead_preferences |       |          |
|-------------+------------------+-------+----------|
|-------------+------------------+-------+----------|
| column name | type             | notes | required |
|-------------+------------------+-------+----------|
| id          | uuid             | PK    | Y        |
|-------------+------------------+-------+----------|
| name        | string           |       | Y        |
| slug        | string           |       | Y        |
| active      | boolean          |       | Y        |
|-------------+------------------+-------+----------|
| created_at  | datetime         |       | Y        |
| updated_at  | datetime         |       | Y        |
|-------------+------------------+-------+----------|
```

## Relationships

```
has_many :leads
```

## Indexes

TODO
* active

# Properties

Properties correspond to the properties that Leads are interested in.

```
|--------------+------------+-------+----------|
| Table:       | properties |       |          |
|--------------+------------+-------+----------|
|--------------+------------+-------+----------|
| column name  | type       | notes | required |
|--------------+------------+-------+----------|
| id           | uuid       | PK    | Y        |
|--------------+------------+-------+----------|
| name         | string     |       | Y        |
| address1     | string     |       | N        |
| address2     | string     |       | N        |
| address3     | string     |       | N        |
| city         | string     |       | N        |
| state        | string     |       | N        |
| zip          | string     |       | N        |
| country      | string     |       | N        |
| organization | string     |       | N        |
| contact_name | string     |       | N        |
| phone        | string     |       | N        |
| fax          | string     |       | N        |
| email        | string     |       | N        |
| units        | integer    |       | N        |
| notes        | text       |       | N        |
|--------------+------------+-------+----------|
| created_at   | datetime   |       | Y        |
| updated_at   | datetime   |       | Y        |
|--------------+------------+-------+----------|
```

## Relationships

has_many :leads

## Indexes

TODO
