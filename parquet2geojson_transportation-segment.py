import os
import pandas as pd
import geopandas as gpd
from shapely import wkb, geometry
from fastparquet import ParquetFile

# ポリゴンの作成
polygon = geometry.Polygon([(122.934570, 20.425378), (122.934570, 45.551483),
                            (153.986672, 45.551483), (153.986672, 20.425378),
                            (122.934570, 20.425378)])

# GeoDataFramesのリストを作成
gdfs = []

# フォルダ内の全てのファイルを処理
directory_path = "./transportation-segment"  # フォルダへのパスを設定

files = os.listdir(directory_path)  # フォルダ内の全てのファイルを取得
n_files = len(files)  # フォルダ内のファイル数を取得

for i, file_name in enumerate(files, start=1):
    # フォルダ内の各ファイルを処理
    file_path = os.path.join(directory_path, file_name)
    
    print(f"処理中のファイル: {file_name} ({i} / {n_files})")  # 処理中のファイルと処理件数を表示

    # Parquet形式のファイルをpandas DataFrameに読み込む
    pf = ParquetFile(file_path)
    df = pf.to_pandas()

    # WKB形式の地理データをgeometryに変換
    df['geometry'] = df['geometry'].apply(wkb.loads)

    # pandas DataFrameをGeoDataFrameに変換
    gdf = gpd.GeoDataFrame(df, geometry='geometry')

    # Int32Dtype型のカラムを標準のint型に変換
    for col in gdf.select_dtypes(include=[pd.Int32Dtype()]).columns:
        gdf[col] = gdf[col].astype('Int64').fillna(-1).astype('int')

    # リスト型のカラムを文字列型に変換
    for col in gdf.columns:
        if isinstance(gdf[col].iloc[0], list):
            gdf[col] = gdf[col].astype(str)

    # ポリゴン内のデータだけを抽出
    gdf = gdf[gdf.within(polygon)]

    # 得られたGeoDataFrameをリストに追加
    gdfs.append(gdf)

# 全てのGeoDataFrameを1つに連結
combined_gdf = pd.concat(gdfs, ignore_index=True)

# 連結したGeoDataFrameをGeoJSONファイルとして出力
output_filename = "transportation-segment-japan.geojson"  # 出力ファイルのパスを設定
combined_gdf.to_file(output_filename, driver='GeoJSON')
print(f"ファイル{output_filename}を保存しました。")  # ファイルが保存されたことを表示
