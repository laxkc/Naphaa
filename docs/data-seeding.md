# Backend Fake Data Seeding

Use this script to generate realistic datasets for different store types.

Script:

- `/Users/laxmankc/Startup/SME/sme-digital/backend/scripts/seed_fake_data.py`

## Supported store types

- `kirana`
- `pharmacy`
- `cafe`
- `electronics`

## What gets generated

- users + stores
- devices (iOS + Android) per store
- products
- customers
- sales + sale items + sale payments (cash/qr/bank/credit/mixed)
- refunds (partial)
- customer payments
- expenses
- stock movement history

## Run examples

Generate full mixed dataset:

```bash
cd /Users/laxmankc/Startup/SME/sme-digital/backend
.venv/bin/python scripts/seed_fake_data.py \
  --store-types kirana,pharmacy,cafe,electronics \
  --stores-per-type 2 \
  --days 45 \
  --seed 42
```

Generate only kirana and cafe:

```bash
cd /Users/laxmankc/Startup/SME/sme-digital/backend
.venv/bin/python scripts/seed_fake_data.py \
  --store-types kirana,cafe \
  --stores-per-type 1 \
  --days 14 \
  --seed 7
```

## Notes

- The script appends data; it does not delete existing records.
- User phone numbers and device IDs are generated to avoid collisions on reruns.
