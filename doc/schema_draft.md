# Draft Druid Data Schema

## ActiveRecord Models

* Leads
* Lead Sources
* Contacts

# Leads

A Lead combines changeable contact information with relationships to Lead
Sources, lead preferences, user assignment, and state.

```
|---------------------+----------+-------+----------|
| Table:              | leads    |       |          |
|---------------------+----------+-------+----------|
|---------------------+----------+-------+----------|
| column name         | type     | notes | required |
|---------------------+----------+-------+----------|
| id                  | uuid     | PK    | Y        |
|---------------------+----------+-------+----------|
| user_id             | uuid     | FK    | N        |
| lead_source_id      | uuid     | FK    | N        |
| lead_preferences_id | uuid     | FK    | N        |
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

## Relationships

```
has_many: :contacts
belongs_to: :source, class_name: 'LeadSource'
belongs_to: user
has_one: :preference, class_name: 'LeadPreference'
```

## Indexes

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
| min_ft      | integer          |       | N        |
| max_ft      | integer          |       | N        |
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

* lead_id

# Lead Source

A Lead Source is the representation of a lead source _i.e._ Walk-In,
  Phone-Incoming, Phone-Outgoing, Email, rent.com, Other

```
|-------------+--------------+-------+----------|
| Table:      | lead_sources |       |          |
|-------------+--------------+-------+----------|
|-------------+--------------+-------+----------|
| column name | type         | notes | required |
|-------------+--------------+-------+----------|
| id          | uuid         | PK    | Y        |
|-------------+--------------+-------+----------|
| name        | string       |       | Y        |
| incoming    | boolean      |       | Y        |
| slug        | string       |       | Y        |
| active      | boolean      |       | Y        |
|-------------+--------------+-------+----------|
| created_at  | datetime     |       | Y        |
| updated_at  | datetime     |       | Y        |
|-------------+--------------+-------+----------|
```

## Relationships

# Contact

A Contact is address, phone, and messaging information which can be associated with other Models.

```
|------------------+----------+-------+----------|
| Table:           | contacts |       |          |
|------------------+----------+-------+----------|
|------------------+----------+-------+----------|
| column name      | type     | notes | required |
|------------------+----------+-------+----------|
| id               | uuid     | PK    | Y        |
|------------------+----------+-------+----------|
| contactable_id   | int      | FK    | Y        |
| contactable_type | string   | FK    | Y        |
| title            | string   |       | N        |
| first_name       | string   |       | Y        |
| middle_name      | string   |       | Y        |
| last_name        | string   |       | Y        |
| company_name     | string   |       | N        |
| address1         | string   |       | N        |
| address2         | string   |       | N        |
| address3         | string   |       | N        |
| city             | string   |       | N        |
| state            | string   |       | N        |
| zip              | string   |       | N        |
| primary_phone    | string   |       | N        |
| datetime_phone   | string   |       | N        |
| nighttime_phone  | string   |       | N        |
| email            | string   |       | N        |
|------------------+----------+-------+----------|
| created_at       | datetime |       | Y        |
| updated_at       | datetime |       | Y        |
|------------------+----------+-------+----------|
```

