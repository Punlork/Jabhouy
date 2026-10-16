# Customers

Status: open
Blocked by: 04

- `PUT /shops/:shopId/customers/:id`: any Member.
- `DELETE`: owner and editor; 409 `customer_has_credits` if any live Credit points to the Customer.

**Done when:** deleting a Customer with a live Credit gives 409; after deleting that Credit, deleting the Customer works.
