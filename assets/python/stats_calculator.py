import json
import sys
import pandas as pd
import matplotlib.pyplot as plt
from datetime import datetime
import os

def generate_stats(users_json, admins_json, lomba_json, period, output_path):
    try:
        users = json.loads(users_json)
        admins = json.loads(admins_json)
        lomba = json.loads(lomba_json)
        
        df_users = pd.DataFrame(users)
        if df_users.empty:
            df_users = pd.DataFrame(columns=['tanggal_daftar'])
            
        # Pastikan kolom tanggal ada
        if 'tanggal_daftar' not in df_users.columns:
            df_users['tanggal_daftar'] = datetime.now().strftime('%Y-%m-%d')
            
        df_users['tanggal_daftar'] = pd.to_datetime(df_users['tanggal_daftar'])
        
        # Filter berdasarkan periode untuk diagram
        now = datetime.now()
        if period == 'Hari':
            # Statistik per jam atau per hari terakhir
            freq = 'D'
            label = 'Tanggal'
        elif period == 'Bulan':
            freq = 'ME'
            label = 'Bulan'
        else: # Tahun
            freq = 'YE'
            label = 'Tahun'
            
        # Hitung pertumbuhan pengguna
        stats_plot = df_users.resample(freq, on='tanggal_daftar').size()
        
        # Buat Diagram Batang menggunakan Pandas & Matplotlib
        plt.figure(figsize=(10, 6))
        stats_plot.plot(kind='bar', color='skyblue', edgecolor='navy')
        plt.title(f'Statistik Pertumbuhan Pengguna ({period})')
        plt.xlabel(label)
        plt.ylabel('Jumlah Pengguna Baru')
        plt.xticks(rotation=45)
        plt.tight_layout()
        
        # Simpan diagram ke file
        chart_file = os.path.join(output_path, 'chart_stats.png')
        plt.savefig(chart_file)
        plt.close()
        
        # Hitung statistik lainnya
        total_lomba = len(lomba)
        df_lomba = pd.DataFrame(lomba)
        ongoing = 0
        finished = 0
        
        if not df_lomba.empty and 'tanggal' in df_lomba.columns:
            df_lomba['tanggal'] = pd.to_datetime(df_lomba['tanggal'])
            ongoing = len(df_lomba[df_lomba['tanggal'] >= pd.Timestamp(now.date())])
            finished = total_lomba - ongoing
        
        result = {
            "status": "success",
            "data": {
                "total_users": len(users),
                "total_admins": len(admins),
                "total_lomba": total_lomba,
                "ongoing_lomba": ongoing,
                "finished_lomba": finished,
                "chart_path": chart_file,
                "last_updated": now.strftime("%Y-%m-%d %H:%M:%S")
            }
        }
        return json.dumps(result)
        
    except Exception as e:
        return json.dumps({"status": "error", "message": str(e)})

if __name__ == "__main__":
    if len(sys.argv) > 5:
        # Args: users, admins, lomba, period, output_path
        print(generate_stats(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5]))
    else:
        print(json.dumps({"status": "error", "message": "Missing arguments"}))
