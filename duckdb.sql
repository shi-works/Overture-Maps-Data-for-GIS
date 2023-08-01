-- DuckDBのCLIを起動
duckdb

-- 必要な拡張機能をインストールおよびロードし、S3リージョンを設定
INSTALL spatial;
INSTALL httpfs;
LOAD spatial;
LOAD httpfs;
SET s3_region='us-west-2';

-- SQLコマンドを実行
-- admins
COPY (
    SELECT
           type,
           subType,
           localityType,
           adminLevel,
           isoCountryCodeAlpha2,
           JSON(names) AS names,
           JSON(sources) AS sources,
           ST_GeomFromWkb(geometry) AS geometry
      FROM read_parquet('s3://overturemaps-us-west-2/release/2023-07-26-alpha.0/theme=admins/type=*/*', filename=true, hive_partitioning=1)
     WHERE adminLevel = 2
       AND ST_GeometryType(ST_GeomFromWkb(geometry)) IN ('POLYGON','MULTIPOLYGON')
) TO 'countries.geojson'
WITH (FORMAT GDAL, DRIVER 'GeoJSON');

-- SQLコマンドを実行
-- buildings-japan
COPY (
    SELECT
           id,
           updateTime,
           version,
           JSON(names) AS names,
           level,
           height,
           numFloors,
           class,
           JSON(sources) AS sources,
           ST_GeomFromWkb(geometry) AS geometry
      FROM read_parquet('s3://overturemaps-us-west-2/release/2023-07-26-alpha.0/theme=buildings/type=*/*')
     WHERE ST_Within(ST_GeomFromWkb(geometry), ST_Envelope(ST_GeomFromText('POLYGON((122.934570 20.425378, 122.934570 45.551483, 153.986672 45.551483, 153.986672 20.425378, 122.934570 20.425378))')))
) TO 'buildings-japan.fgb'
WITH (FORMAT GDAL, DRIVER 'FlatGeobuf');

-- SQLコマンドを実行
-- places
COPY (
     SELECT
      id,
      updatetime,
      version,
      json_extract_string(names, '$.common[0].value') as name,
      confidence,
      json_extract_string(websites, '$[0]') as websites,
      json_extract_string(socials, '$[0]') as socials,
      emails,
      json_extract_string(phones, '$[0]') as phones,
      addresses,
      sources,
      json_extract_string(categories, '$.main') as category_main,
      json_extract_string(categories, '$.alternate') as categories_alternate,
      json_extract_string(brand, '$.names') as brand_names,
      json_extract_string(brand, '$.wikidata') as brand_wikidata,
      json_extract(bbox,'$.minx') as x,
      json_extract(bbox,'$.miny') as y,
      FROM read_parquet('s3://overturemaps-us-west-2/release/2023-07-26-alpha.0/theme=places/type=place/*')
) TO 'places.csv' (HEADER, DELIMITER ',');

-- SQLコマンドを実行
-- places-japan
COPY (
     SELECT
      id,
      updatetime,
      version,
      json_extract_string(names, '$.common[0].value') as name,
      confidence,
      json_extract_string(websites, '$[0]') as websites,
      json_extract_string(socials, '$[0]') as socials,
      emails,
      json_extract_string(phones, '$[0]') as phones,
      addresses,
      sources,
      json_extract_string(categories, '$.main') as category_main,
      json_extract_string(categories, '$.alternate') as categories_alternate,
      json_extract_string(brand, '$.names') as brand_names,
      json_extract_string(brand, '$.wikidata') as brand_wikidata,
      json_extract(bbox,'$.minx') as x,
      json_extract(bbox,'$.miny') as y
      FROM read_parquet('s3://overturemaps-us-west-2/release/2023-07-26-alpha.0/theme=places/type=place/*')
      WHERE json_extract(bbox,'$.minx') BETWEEN 122.934570 AND 153.986672 
      AND json_extract(bbox,'$.miny') BETWEEN 20.425378 AND 45.551483
) TO 'places-japan.csv' 
WITH (FORMAT CSV, HEADER, DELIMITER ',');

-- SQLコマンドを実行
-- transportation-connector-japan
COPY (
     SELECT
      id,
      updatetime,
      version,
      level,
      subtype,
      connectors,
      road,
      sources,
      json_extract(bbox,'$.minx') as x,
      json_extract(bbox,'$.miny') as y
      FROM read_parquet('s3://overturemaps-us-west-2/release/2023-07-26-alpha.0/theme=transportation/type=connector/*')
      WHERE json_extract(bbox,'$.minx') BETWEEN 122.934570 AND 153.986672 
      AND json_extract(bbox,'$.miny') BETWEEN 20.425378 AND 45.551483
) TO 'transportation-connector-japan.csv' 
WITH (FORMAT CSV, HEADER, DELIMITER ',');



