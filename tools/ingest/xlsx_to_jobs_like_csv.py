#!/usr/bin/env python3
import argparse
import sys
import pandas as pd

# Map marketplace/product values to canonical user types
USER_TYPE_NORMALIZE = {
    "ridesharing": "rides",
    "ride": "rides",
    "rides": "rides",
    "taxi": "rides",
    "uberx": "rides",
    "uber": "rides",
    "food_delivery": "food",
    "food": "food",
    "eats": "food",
    "delivery": "food",
    "courier": "food",
}

def norm_user_type(x):
    if pd.isna(x):
        return None
    s = str(x).strip().lower()
    return USER_TYPE_NORMALIZE.get(s, s)

def parse_utc(series):
    """Parse to UTC ISO8601 Z (drop tz info by formatting to Z)."""
    ts = pd.to_datetime(series, errors="coerce", utc=True)
    return ts

def prefer(*cols):
    """Return the first non-null series from the provided columns (in the same DataFrame)."""
    result = None
    for s in cols:
        if s is None:
            continue
        if result is None:
            result = s.copy()
        else:
            result = result.fillna(s)
    return result

def load_jobs_like_sheet(xls, default_city_id):
    if "jobs_like" not in xls.sheet_names:
        return pd.DataFrame()

    df = xls.parse("jobs_like")
    if df.empty:
        return pd.DataFrame()

    # Columns seen in your sample:
    # - job_uuid
    # - marketplace
    # - datestr
    # - acceptor_uuid
    # - requester_uuid
    # - begin_checkpoint.actual_location_hexagon_id9
    # - begin_checkpoint.actual_location_latitude
    # - begin_checkpoint.actual_location_longitude
    # - begin_checkpoint.city_id
    # - begin_checkpoint.ata_utc
    # - end_checkpoint.actual_location_hexagon_id9
    # - end_checkpoint.city_id
    # - end_checkpoint.ata_utc
    # - global_product_name
    # - product_type_name
    # - fulfillment_job_status

    cols = {c.lower(): c for c in df.columns}
    def c(name): return cols.get(name.lower())

    # zone: prefer begin hex, else end hex
    zone = prefer(df.get(c("begin_checkpoint.actual_location_hexagon_id9")),
                  df.get(c("end_checkpoint.actual_location_hexagon_id9")))

    # ts: prefer begin ata_utc, else end ata_utc, else datestr
    ts_raw = prefer(df.get(c("begin_checkpoint.ata_utc")),
                    df.get(c("end_checkpoint.ata_utc")),
                    df.get(c("datestr")))
    ts = parse_utc(ts_raw)

    # city_id: prefer begin city, else end city, else default
    city_series = prefer(df.get(c("begin_checkpoint.city_id")),
                         df.get(c("end_checkpoint.city_id")))
    if city_series is None:
        city = pd.Series([default_city_id] * len(df), index=df.index)
    else:
        city = city_series.fillna(default_city_id)

    # user_type: prefer marketplace, else product_type_name, else global_product_name
    user_raw = prefer(df.get(c("marketplace")),
                      df.get(c("product_type_name")),
                      df.get(c("global_product_name")))
    user = user_raw.apply(norm_user_type) if user_raw is not None else pd.Series(["unknown"]*len(df))

    out = pd.DataFrame({
        "city_id": pd.to_numeric(city, errors="coerce"),
        "zone": zone.astype(str) if zone is not None else pd.Series([None]*len(df)),
        "ts": ts,
        "user_type": user.fillna("unknown"),
        "jobs_like": 1.0,                # 1 event per row; will be aggregated later
        "source_sheet": "jobs_like",
    })

    # Drop rows without essential fields
    out = out.dropna(subset=["city_id", "zone", "ts", "user_type"])
    out["city_id"] = out["city_id"].astype(int)
    return out

def load_rides_trips(xls):
    if "rides_trips" not in xls.sheet_names:
        return pd.DataFrame()

    df = xls.parse("rides_trips")
    if df.empty:
        return pd.DataFrame()

    cols = {c.lower(): c for c in df.columns}
    def c(name): return cols.get(name.lower())

    # zone: prefer pickup_hex_id9, else drop_hex_id9
    zone = prefer(df.get(c("pickup_hex_id9")),
                  df.get(c("drop_hex_id9")))

    # ts: start_time
    ts = parse_utc(df.get(c("start_time")))

    city = df.get(c("city_id"))
    out = pd.DataFrame({
        "city_id": pd.to_numeric(city, errors="coerce"),
        "zone": zone.astype(str) if zone is not None else pd.Series([None]*len(df)),
        "ts": ts,
        "user_type": "rides",
        "jobs_like": 1.0,
        "source_sheet": "rides_trips",
    })
    out = out.dropna(subset=["city_id", "zone", "ts"])
    out["city_id"] = out["city_id"].astype(int)
    return out

def load_eats_orders(xls):
    if "eats_orders" not in xls.sheet_names:
        return pd.DataFrame()

    df = xls.parse("eats_orders")
    if df.empty:
        return pd.DataFrame()

    cols = {c.lower(): c for c in df.columns}
    def c(name): return cols.get(name.lower())

    zone = prefer(df.get(c("pickup_hex_id9")),
                  df.get(c("drop_hex_id9")))
    ts = parse_utc(df.get(c("start_time")))
    city = df.get(c("city_id"))

    out = pd.DataFrame({
        "city_id": pd.to_numeric(city, errors="coerce"),
        "zone": zone.astype(str) if zone is not None else pd.Series([None]*len(df)),
        "ts": ts,
        "user_type": "food",
        "jobs_like": 1.0,
        "source_sheet": "eats_orders",
    })
    out = out.dropna(subset=["city_id", "zone", "ts"])
    out["city_id"] = out["city_id"].astype(int)
    return out

def main():
    ap = argparse.ArgumentParser(description="Build normalized jobs_like CSV from multi-sheet Excel.")
    ap.add_argument("xlsx", help="Path to uber_hackathon_v2_mock_data.xlsx")
    ap.add_argument("--out", default="docker/db/init/jobs_like.csv",
                    help="Output CSV path")
    ap.add_argument("--default-city-id", type=int, default=1,
                    help="Fallback city_id if missing")
    ap.add_argument("--bucket-minutes", type=int, default=60,
                    help="Time bucket size in minutes (0 = no bucketing). Default 60")
    args = ap.parse_args()

    try:
        xls = pd.ExcelFile(args.xlsx)
    except Exception as e:
        print(f"ERROR: cannot read Excel: {e}")
        sys.exit(1)

    parts = []
    a = load_jobs_like_sheet(xls, args.default_city_id)
    if not a.empty: parts.append(a)
    b = load_rides_trips(xls)
    if not b.empty: parts.append(b)
    c = load_eats_orders(xls)
    if not c.empty: parts.append(c)

    if not parts:
        print("ERROR: No usable sheets found (jobs_like, rides_trips, eats_orders).")
        sys.exit(2)

    df = pd.concat(parts, ignore_index=True)

    # Optional bucketing (recommended for smaller, smoother dataset)
    if args.bucket_minutes and args.bucket_minutes > 0:
        df["ts"] = pd.to_datetime(df["ts"], utc=True)
        df["ts"] = df["ts"].dt.floor(f"{args.bucket_minutes}min")
        grp = (df
               .groupby(["city_id", "zone", "ts", "user_type", "source_sheet"], as_index=False)
               .agg(jobs_like=("jobs_like", "sum")))
        out = grp
    else:
        out = df

    # Final formatting
    out = out[["city_id", "zone", "ts", "user_type", "jobs_like", "source_sheet"]].copy()
    out["ts"] = pd.to_datetime(out["ts"], utc=True).dt.strftime("%Y-%m-%dT%H:%M:%SZ")
    out.to_csv(args.out, index=False)
    print(f"OK: wrote {len(out):,} rows to {args.out}")

if __name__ == "__main__":
    main()
