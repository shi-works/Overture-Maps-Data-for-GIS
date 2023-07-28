-- DuckDBのCLIを起動
duckdb

-- 必要な拡張機能をインストールおよびロードし、S3リージョンを設定
INSTALL spatial;
INSTALL httpfs;
LOAD spatial;
LOAD httpfs;
SET s3_region='us-west-2';

-- SQLコマンドを実行
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
) TO 'buildings.fgb'
WITH (FORMAT GDAL, DRIVER 'FlatGeobuf');