# Jabhouy

An offline-first app a small shop uses for inventory, customer loans, and income from bank notifications.

## Accounts

**User**:
The person signed in to the app who runs the shop. One User can have several Sign-in methods.
_Avoid_: Account, customer

**Shop**:
The items, categories, customers and loans that one or more Users work on together, each signing in as themselves.
_Avoid_: Store, business account

**Username**:
The unique handle a User signs in with using a password. A User who joined with Google picks one before first reaching Home.
_Avoid_: Login, handle, display name

**Sign-in method**:
A way for a User to prove who they are: username and password, or Google.
_Avoid_: Provider, login type

**Account linking**:
Attaching Google as a Sign-in method to an existing User whose email matches and that Google has verified.
_Avoid_: Merging, account sync

**Member**:
A User who belongs to a Shop, with one role: owner, editor or viewer.
_Avoid_: Staff, employee, collaborator

**Active Shop**:
The Shop a User is working in right now on their phone; a User in several Shops switches between them.
_Avoid_: Current store, selected account

**Owner**:
The Member who created the Shop and manages its settings and Members.

**Editor**:
A Member who can change prices, categories and units.

**Viewer**:
A Member who can see prices and record Credits but cannot change prices.
_Avoid_: Read-only user

## Shop

**Item**:
A thing the Shop sells, with one or more Price options.
_Avoid_: Product, shop item

**Price option**:
One way an Item is sold, such as a bottle or a case of 24, with its own unit and prices.
_Avoid_: Variant, pack, single

## Credit

**Customer**:
A person who takes goods from a Shop and may owe it money.
_Avoid_: Loaner, borrower, client

**Credit**:
One occasion a Customer took goods without paying, recorded with the amount owed and whether it has been paid.
_Avoid_: Loan, loaner, debt, IOU

**Credit item**:
One thing taken on a Credit, with the name, unit and price it had when it was taken.
_Avoid_: Credit line, loan item
