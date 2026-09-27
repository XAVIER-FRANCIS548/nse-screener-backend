import json
import urllib.request
import ssl
import time
import pandas as pd
import numpy as np
import openpyxl
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from openpyxl.utils import get_column_letter

# Your Stock List
NSE_TICKERS = [
    "63MOONS.NS", "AAATECH.NS", "ABCAPITAL.NS", "ABINFRA.NS", "ADANIPORTS.NS", "ADANIPOWER.NS", 
    "ANANTRAJ.NS", "APARINDS.NS", "APLAPOLLO.NS", "APOLLO.NS", "AQYLON.NS", "ARIHANT.NS", 
    "ARVEE.NS", "ASAHIINDIA.NS", "ASHOKLEY.NS", "ASTERDM.NS", "ASTRAMICRO.NS", "BANARBEADS.NS", 
    "BANCOINDIA.NS", "BANKBARODA.NS", "BBOX.NS", "BDL.NS", "BEL.NS", "BHAGYANGR.NS", 
    "BHARATFORG.NS", "BHARTIARTL.NS", "BHEL.NS", "BOSCHLTD.NS", "CANBK.NS", "CAPLIPOINT.NS", 
    "CASTROLIND.NS", "CCL.NS", "CEATLTD.NS", "CEMPRO.NS", "CENTUM.NS", "CGPOWER.NS", 
    "COALINDIA.NS", "COCHINSHIP.NS", "CUBEXTUB.NS", "CUMMINSIND.NS", "CUPID.NS", "DIAMONDYD.NS", 
    "DYNAMATECH.NS", "EASTSILK.NS", "EICHERMOT.NS", "ESABINDIA.NS", "ESCORTS.NS", "FEDERALBNK.NS", 
    "FIEMIND.NS", "FOSECOIND.NS", "GABRIEL.NS", "GALLANTT.NS", "GESHIP.NS", "GFSTEELS.NS", 
    "GODFRYPHLP.NS", "GOKULAGRO.NS", "GOODLUCK.NS", "GPPL.NS", "GRASIM.NS", "GRSE.NS", 
    "GVT&D.NS", "HAL.NS", "HBLENGINE.NS", "HCG.NS", "HDFCBANK.NS", "HECPROJECT.NS", 
    "HINDZINC.NS", "HIRECT.NS", "HSCL.NS", "HUDCO.NS", "ICICIBANK.NS", "IDBI.NS", 
    "IMFA.NS", "INDIACEM.NS", "INDIANB.NS", "INDNIPPON.NS", "INDOTECH.NS", "INDSWFTLAB.NS", 
    "IOC.NS", "IZMO.NS", "JAYNECOIND.NS", "JINDALPHOT.NS", "JINDALSTEL.NS", "JPOLYINVST.NS", 
    "JSL.NS", "JSWHL.NS", "JSWSTEEL.NS", "KARURVYSYA.NS", "KDDL.NS", "KEI.NS", 
    "KERNEX.NS", "KEYFINSERV.NS", "KHAITANLTD.NS", "KINGFA.NS", "KIRLOSBROS.NS", "KIRLOSENG.NS", 
    "KOVAI.NS", "LEMONTREE.NS", "LGBBROSLTD.NS", "LLOYDSENGG.NS", "LT.NS", "LTFOODS.NS", 
    "LUMAXTECH.NS", "M&M.NS", "MAHABANK.NS", "MAHSCOOTER.NS", "MANAKCOAT.NS", "MANAKSTEEL.NS", 
    "MANINDS.NS", "MARICO.NS", "MAZDOCK.NS", "MBAPL.NS", "MCX.NS", "MINDACORP.NS", 
    "MPSLTD.NS", "MRPL.NS", "NAVA.NS", "NDRAUTO.NS", "NESCO.NS", "NEULANDLAB.NS", 
    "NH.NS", "NHPC.NS", "NORBTEAEXP.NS", "NTPC.NS", "OIL.NS", "ONGC.NS", 
    "PASHUPATI.NS", "PENIND.NS", "PFOCUS.NS", "PGEL.NS", "PGIL.NS", "PHOENIXLTD.NS", 
    "PIDILITIND.NS", "PNB.NS", "PNBHOUSING.NS", "POCL.NS", "POLYCAB.NS", "POWERINDIA.NS", 
    "PRECWIRE.NS", "PREMEXPLN.NS", "PREMIERPOL.NS", "PRICOLLTD.NS", "PVP.NS", "RADICO.NS", 
    "REDINGTON.NS", "REFEX.NS", "ROHLTD.NS", "RPGLIFE.NS", "SALSTEEL.NS", "SARDAEN.NS", 
    "SBIN.NS", "SCHAEFFLER.NS", "SCI.NS", "SHAKTIPUMP.NS", "SHRIPISTON.NS", "SHRIRAMFIN.NS", 
    "SIGMAADV.NS", "SMLMAH.NS", "SOLARINDS.NS", "SOMATEX.NS", "STEL.NS", "STLTECH.NS", 
    "SUNDARMFIN.NS", "SUNFLAG.NS", "SUVEN.NS", "SVLL.NS", "SWARAJENG.NS", "TALBROAUTO.NS", 
    "TARACHAND.NS", "TARIL.NS", "TATAINVEST.NS", "TATASTEEL.NS", "TBZ.NS", "TDPOWERSYS.NS", 
    "TEAMGTY.NS", "TFCILTD.NS", "THANGAMAYL.NS", "THOMASCOTT.NS", "TI.NS", "TIPSMUSIC.NS", 
    "TSFINV.NS", "TVSHLTD.NS", "TVSMOTOR.NS", "UNIONBANK.NS", "UNIVCABLES.NS", "UNOMINDA.NS", 
    "USHAMART.NS", "V2RETAIL.NS", "VADILALIND.NS", "VEDL.NS", "VENUSREM.NS", "VIMTALABS.NS", 
    "VISHNU.NS", "VOLTAMP.NS", "VSSL.NS", "WEBELSOLAR.NS", "WELCORP.NS", "WELENT.NS", 
    "WELINV.NS", "ZENTEC.NS", "ZUARI.NS", "ZUARIIND.NS"
]


def fetch_stock_data(ticker, period_years=2):
    """Fetches daily price history from Yahoo Finance."""
    end_time = int(pd.Timestamp.now().timestamp())
    start_time = int((pd.Timestamp.now() - pd.Timedelta(days=period_years * 365)).timestamp())
    
    url = f"https://query1.finance.yahoo.com/v8/finance/chart/{ticker}?period1={start_time}&period2={end_time}&interval=1d"
    headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0 Safari/537.36'}
    
    try:
        ctx = ssl.create_default_context()
        ctx.check_hostname = False
        ctx.verify_mode = ssl.CERT_NONE

        req = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req, context=ctx, timeout=8) as response:
            data = json.loads(response.read().decode('utf-8'))
            
        result = data['chart']['result'][0]
        timestamps = result['timestamp']
        indicators = result['indicators']['quote'][0]
        
        df = pd.DataFrame({
            'High': indicators.get('high'),
            'Low': indicators.get('low'),
            'Close': indicators.get('close'),
            'Volume': indicators.get('volume')
        }, index=pd.to_datetime(timestamps, unit='s'))
        
        df.dropna(subset=['Close'], inplace=True)
        df['Date'] = df.index.date
        df.drop_duplicates(subset=['Date'], keep='last', inplace=True)
        
        return df
    except Exception:
        return None


def calculate_trendlines(df, lookback=60):
    """Calculates linear regression trendlines for recent support and resistance levels."""
    recent_df = df.tail(lookback)
    x = np.arange(len(recent_df))
    
    low_slope, low_intercept = np.polyfit(x, recent_df['Low'].values, 1)
    high_slope, high_intercept = np.polyfit(x, recent_df['High'].values, 1)

    support_tl = low_slope * x[-1] + low_intercept
    resistance_tl = high_slope * x[-1] + high_intercept

    if low_slope > 0.05 and high_slope > 0.05:
        pattern = "ASCENDING"
    elif low_slope < -0.05 and high_slope < -0.05:
        pattern = "DESCENDING"
    else:
        pattern = "SIDEWAYS"

    return round(support_tl, 2), round(resistance_tl, 2), pattern


def analyze_single_stock(ticker):
    """Processes technical indicators, ATH, and daily price changes."""
    df = fetch_stock_data(ticker)
    if df is None or len(df) < 100:
        return None

    today_close = round(df['Close'].iloc[-1], 2)
    yesterday_close = round(df['Close'].iloc[-2], 2)
    
    price_change_inr = round(today_close - yesterday_close, 2)
    daily_change_pct = round(((today_close - yesterday_close) / yesterday_close) * 100, 2)

    # Daily EMAs
    df['EMA_20'] = df['Close'].ewm(span=20, adjust=False).mean()
    df['EMA_50'] = df['Close'].ewm(span=50, adjust=False).mean()

    # 30-Week Macro EMA
    df_weekly = df['Close'].resample('W-FRI').last().to_frame()
    df_weekly['EMA_30W'] = df_weekly['Close'].ewm(span=30, adjust=False).mean()
    df = pd.merge_asof(df.sort_index(), df_weekly[['EMA_30W']].sort_index(), left_index=True, right_index=True, direction='backward')
    df['EMA_30W'] = df['EMA_30W'].ffill()

    # RSI Calculation
    delta = df['Close'].diff()
    gain = (delta.where(delta > 0, 0)).rolling(14).mean()
    loss = (-delta.where(delta < 0, 0)).rolling(14).mean()
    rs = gain / loss.replace(0, np.nan)
    df['RSI'] = 100 - (100 / (1 + rs))

    # MACD Calculation
    df['EMA_12'] = df['Close'].ewm(span=12, adjust=False).mean()
    df['EMA_26'] = df['Close'].ewm(span=26, adjust=False).mean()
    df['MACD'] = df['EMA_12'] - df['EMA_26']
    df['MACD_Signal'] = df['MACD'].ewm(span=9, adjust=False).mean()

    # Trendlines
    supp_tl, res_tl, channel_pattern = calculate_trendlines(df)

    latest = df.iloc[-1]

    # ATH Calculations
    ath = round(df['High'].max(), 2)
    down_from_ath_pct = round(((ath - today_close) / ath) * 100, 2)

    ema_30w = round(latest['EMA_30W'], 2) if not pd.isna(latest['EMA_30W']) else 0.0
    rsi = round(latest['RSI'], 2) if not pd.isna(latest['RSI']) else 0.0

    # Score Engine
    score = 0
    macro_trend = "BULLISH" if today_close > ema_30w else "BEARISH"
    
    if today_close > ema_30w: score += 2
    else: score -= 2
    
    if latest['EMA_20'] > latest['EMA_50']: score += 1
    else: score -= 1
    
    if latest['MACD'] > latest['MACD_Signal']: score += 1
    else: score -= 1

    if today_close > res_tl: score += 2
    elif today_close < supp_tl: score -= 2

    # Output Verdict Mapping
    if score >= 3: verdict = "STRONG BUY"
    elif 1 <= score <= 2: verdict = "MODERATE BUY"
    elif score == 0: verdict = "NEUTRAL / HOLD"
    else: verdict = "AVOID / BEARISH"

    return {
        "Ticker": ticker.replace(".NS", ""),
        "Yesterday Close (INR)": yesterday_close,
        "Today Close (INR)": today_close,
        "Price Change (INR)": price_change_inr,
        "Daily Change %": daily_change_pct,
        "ATH Value": ath,
        "Down % from ATH": down_from_ath_pct,
        "30W Macro EMA": ema_30w,
        "Macro Trend": macro_trend,
        "RSI (14)": rsi,
        "Short Trend (EMA 20/50)": "BULLISH" if latest['EMA_20'] > latest['EMA_50'] else "BEARISH",
        "MACD Status": "BULLISH" if latest['MACD'] > latest['MACD_Signal'] else "BEARISH",
        "Channel Pattern": channel_pattern,
        "TL Support": supp_tl,
        "TL Resistance": res_tl,
        "Overall Score": score,
        "Signal Verdict": verdict,
        "Target Price": round(max(today_close * 1.10, res_tl * 1.05), 2),
        "Stop Loss": round(min(today_close * 0.95, supp_tl * 0.98), 2)
    }


def style_worksheet(ws):
    """Helper function to apply styling, alignment, and auto-fit to any worksheet."""
    ws.views.sheetView[0].showGridLines = True
    
    # Header Styles
    header_fill = PatternFill(start_color="1F497D", end_color="1F497D", fill_type="solid") # Dark Navy
    header_font = Font(name="Calibri", size=11, bold=True, color="FFFFFF")
    
    # Conditional Formatting Fills & Fonts
    green_fill = PatternFill(start_color="E2EFDA", end_color="E2EFDA", fill_type="solid")
    green_font = Font(name="Calibri", size=11, bold=True, color="375623")
    
    strong_green_fill = PatternFill(start_color="C6EFCE", end_color="C6EFCE", fill_type="solid")
    strong_green_font = Font(name="Calibri", size=11, bold=True, color="006100")
    
    red_fill = PatternFill(start_color="FCE4D6", end_color="FCE4D6", fill_type="solid")
    red_font = Font(name="Calibri", size=11, bold=True, color="C00000")
    
    neutral_fill = PatternFill(start_color="FFF2CC", end_color="FFF2CC", fill_type="solid")
    neutral_font = Font(name="Calibri", size=11, color="7F6000")
    
    thin_border = Border(
        left=Side(style='thin', color='D9D9D9'),
        right=Side(style='thin', color='D9D9D9'),
        top=Side(style='thin', color='D9D9D9'),
        bottom=Side(style='thin', color='D9D9D9')
    )
    
    # Format Headers
    for col in range(1, ws.max_column + 1):
        cell = ws.cell(row=1, column=col)
        cell.fill = header_fill
        cell.font = header_font
        cell.alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)
    
    ws.row_dimensions[1].height = 28

    # Format Data Rows
    for row in range(2, ws.max_row + 1):
        ws.row_dimensions[row].height = 20
        for col in range(1, ws.max_column + 1):
            cell = ws.cell(row=row, column=col)
            cell.border = thin_border
            
            if isinstance(cell.value, (int, float)):
                cell.alignment = Alignment(horizontal="right", vertical="center")
            else:
                cell.alignment = Alignment(horizontal="center", vertical="center")

            val = str(cell.value).upper() if cell.value is not None else ""
            
            if val in ["STRONG BUY"]:
                cell.fill = strong_green_fill
                cell.font = strong_green_font
            elif val in ["BULLISH", "MODERATE BUY"]:
                cell.fill = green_fill
                cell.font = green_font
            elif val in ["BEARISH", "AVOID / BEARISH"]:
                cell.fill = red_fill
                cell.font = red_font
            elif val in ["NEUTRAL / HOLD", "SIDEWAYS"]:
                cell.fill = neutral_fill
                cell.font = neutral_font

    # Freeze Header & Auto-fit Columns
    ws.freeze_panes = "A2"
    for col in ws.columns:
        max_len = max(len(str(cell.value or '')) for cell in col)
        col_letter = get_column_letter(col[0].column)
        ws.column_dimensions[col_letter].width = max(max_len + 4, 12)


def format_excel_output(file_path):
    """Applies formatting across all sheets in the Excel file."""
    wb = openpyxl.load_workbook(file_path)
    for sheet_name in wb.sheetnames:
        ws = wb[sheet_name]
        style_worksheet(ws)
    wb.save(file_path)


def run_batch_screener(ticker_list, output_excel="NSE_Batch_Technical_Analysis.xlsx"):
    print("=" * 70)
    print(f" STARTING BATCH TECHNICAL SCANNER FOR {len(ticker_list)} STOCKS")
    print("=" * 70)
    
    results = []
    
    for idx, ticker in enumerate(ticker_list, 1):
        print(f"[{idx}/{len(ticker_list)}] Processing: {ticker} ...", end=" ")
        data = analyze_single_stock(ticker)
        
        if data:
            results.append(data)
            print(f"DONE | Verdict: {data['Signal Verdict']}")
        else:
            print("FAILED / NO DATA")
            
        time.sleep(0.2)

    if results:
        results_df = pd.DataFrame(results)
        results_df.sort_values(by="Overall Score", ascending=False, inplace=True)
        
        # Filter Strong Buy stocks for the Opportunity tab
        opportunity_df = results_df[results_df["Signal Verdict"] == "STRONG BUY"].copy()

        # Write both dataframes into separate Excel sheets
        with pd.ExcelWriter(output_excel, engine='openpyxl') as writer:
            results_df.to_excel(writer, index=False, sheet_name="Technical_Screener")
            
            if not opportunity_df.empty:
                opportunity_df.to_excel(writer, index=False, sheet_name="Opportunity_Stocks")
            else:
                # If no Strong Buy, create tab with header note
                empty_df = pd.DataFrame({"Note": ["No STRONG BUY opportunities detected in this scan."]})
                empty_df.to_excel(writer, index=False, sheet_name="Opportunity_Stocks")

        # Format both sheets with styling
        format_excel_output(output_excel)
        
        print("\n" + "=" * 70)
        print(f" SUCCESS: Results exported to '{output_excel}' with 'Opportunity_Stocks' sheet created.")
        print("=" * 70)

if __name__ == "__main__":
    run_batch_screener(NSE_TICKERS)
