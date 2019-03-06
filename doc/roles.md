# User Roles

* Administrator
* Corporate
* Agent

## Administrator

Members of the `Administrator` role are _application_ administrators.

Users are directly associated to a Role via `users.role_id`

Examples:
* Website administrators

### Access

Full read/write access to all features.

## Corporate

Members of the `Corporate` role are privileged users.

### Access

* Properties: FULL
  * Unit Types: FULL
  * Units: FULL
* Teams: FULL
* Leads: FULL
* Users: FULL
* Messages: READ
* Engagement Policy: FULL

Examples:
* HR
* Leadership

## Agent

Members of the `Agent` role are typical users, and property agents/managers.

## Access

* Properties: By TeamRole
  * Unit Types: By TeamRole
  * Units: By TeamRole
* Teams: By TeamRole
* Leads: By TeamRole
* Users: By TeamRole
* Messages:
  * Own: FULL
  * Others: NONE
* Leads: By TeamRole
* Engagement Policy: READ

# Team Membership

Users may belong to a single Team (by convention). This association is created via a
`TeamUser` record.

## Lead

Members of the `Lead` TeamRole are privileged users within their Team.

A Lead is indicated by the `team_users.is_lead` column/attribute, which defaults to `false`

Examples:
* Talent Resource Managers

### Access

* Properties: FULL in Team
  * Unit Types: FULL in Team
  * Units: FULL in Team
* Teams:
  * Own: FULL
  * Other: NONE
* Leads:
  * Own: FULL
  * For Team Properties: FULL
  * For Other Properties: NONE
* Users:
  * Team Users: FULL
  * Other Users: NONE
* Messages:
  * Own: FULL
  * Others: NONE
* Engagement Policy: READ

## Non-Leads

A non-lead team member has a `team_users` record with an `is_lead` attribute marked as false (default)

Examples:
* Property Manager
* Agent

### Access

* Properties: By PropertyRole
  * Unit Types: By PropertyRole
  * Units: By PropertyRole
* Teams:
  * Own: READ
  * Other: NONE
* Leads:
  * Own: FULL
  * For Own Properties: By PropertyRole
  * For Other Properties: NONE
* Users:
  * Team Users: READ
  * Other Users: NONE
* Messages:
  * Own: FULL
  * Others: NONE
* Engagement Policy: READ

# Property Roles

Users may belong to one, several, or no Properties. This association is created via
 one or more `PropertyUser` records.

A `PropertyUser` record is always associated with a `PropertyRole` which determines that
User's level of access within the scope of the Property.

* Manager
* Agent

## Manager

A User with privileged access for a specific Property.

Examples:
* A property manager

### Access

* Properties:
  * Own: Full
  * Other: None
  * Unit Types:
    * Own: Full
    * Other: None
  * Units:
    * Own: Full
    * Other: None
* Teams:
  * Own: READ
  * Other: NONE
* Leads:
  * Own: FULL
  * For Own Properties: FULL
  * For Other Properties: NONE
* Users:
  * Team Users:
    * For Own Properties: FULL
    * For Other Properties: NONE
  * Other Users: NONE
* Messages:
  * Own: FULL
  * Own Property Users: READ
* Engagement Policy: READ

## Agent

A User concerned mainly with Lead management within the scope of their Property.

* Properties:
  * Own: READ
  * Other: NONE
  * Unit Types:
    * Own: READ
    * Other: NONE
  * Units:
    * Own: READ
    * Other: NONE
* Teams:
  * Own: READ
  * Other: NONE
* Leads:
  * Own: FULL
  * For Own Properties: FULL
  * For Other Properties: NONE
* Users:
  * Team Users: NONE
  * Other Users: NONE
* Messages:
  * Own: FULL
  * Others: NONE
* Engagement Policy: READ
