import csv
import json
import urllib.request
from pathlib import Path

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.font_manager as fm
from matplotlib.patches import Patch

HERE = Path(__file__).resolve().parent
RAW = HERE / 'gfdd'
COUNTRIES = dict(FRA='France', USA='United States', DEU='Germany', ITA='Italy',
    ESP='Spain', GBR='United Kingdom', JPN='Japan', CAN='Canada', AUS='Australia',
    AUT='Austria', BEL='Belgium', DNK='Denmark', FIN='Finland', GRC='Greece',
    IRL='Ireland', NLD='Netherlands', NZL='New Zealand', NOR='Norway', PRT='Portugal',
    SWE='Sweden', CHE='Switzerland', KOR='South Korea')
FIGURES = [
 ('structure', [('GFDD.OI.01', 'A. Three-bank concentration', 'Percent of bank assets'),
                ('GFDD.SI.03', 'B. Bank capital and reserves', 'Percent of bank assets')]),
 ('depth', [('GFDD.DI.01', 'A. Private credit by banks', 'Percent of gross domestic product'),
            ('GFDD.OI.02', 'B. Bank deposits', 'Percent of gross domestic product')]),
 ('balance_sheets', [('GFDD.SI.04', 'A. Bank credit relative to deposits', 'Percent of bank deposits'),
                     ('GFDD.SI.02', 'B. Nonperforming loans', 'Percent of gross loans')]),
 ('firm_use', [('GFDD.AI.03', 'A. Firms with a loan or credit line', 'Percent of firms'),
               ('GFDD.AI.29', 'B. Firms using banks for working capital', 'Percent of firms')])]

def latest(key):
    path = RAW / f'{key}_all_years.json'
    if not path.exists():
        url = (f'https://api.worldbank.org/v2/country/{";".join(COUNTRIES)}/indicator/{key}'
               '?source=32&format=json&per_page=10000')
        with urllib.request.urlopen(url) as response:
            content = response.read()
        json.loads(content)
        RAW.mkdir(exist_ok=True)
        path.write_bytes(content)
    payload = json.loads(path.read_bytes())
    assert payload[0]['pages'] == 1
    rows = []
    for code, country in COUNTRIES.items():
        valid = [r for r in payload[1] if r['countryiso3code'] == code and r['value'] is not None]
        if valid:
            r = max(valid, key=lambda r: int(r['date']))
            rows.append(dict(country=country, indicator=key, year=r['date'], value=r['value']))
    return rows

FONT_PATH = Path('/System/Library/Fonts/Supplemental/GillSans.ttc')
BASE_FONT = 'DejaVu Sans'
if FONT_PATH.exists():
    try:
        import tempfile
        from fontTools.ttLib import TTCollection
        tmp = Path(tempfile.mkdtemp())
        for i, face in enumerate(TTCollection(str(FONT_PATH)).fonts):
            face.save(tmp / f'gillsans_{i}.ttf')
            fm.fontManager.addfont(str(tmp / f'gillsans_{i}.ttf'))
    except ImportError:
        fm.fontManager.addfont(str(FONT_PATH))
    BASE_FONT = 'Gill Sans'
NAVY, MAROON = '#1A476F', '#90353B'
plt.rcParams.update({'font.family': BASE_FONT, 'font.size': 11, 'figure.dpi': 170,
    'figure.facecolor': 'white', 'axes.facecolor': 'white', 'axes.edgecolor': '#1A1A1A',
    'axes.linewidth': .6, 'axes.titlesize': 12, 'axes.titleweight': 'semibold',
    'axes.labelsize': 11, 'axes.spines.top': False, 'axes.spines.right': False,
    'axes.axisbelow': True, 'grid.color': '#E6E6E6', 'grid.linewidth': .4,
    'xtick.labelsize': 10, 'ytick.labelsize': 10, 'text.color': '#1A1A1A',
    'legend.frameon': False, 'savefig.facecolor': 'white', 'pdf.fonttype': 42})

plotted = []
for name, panels in FIGURES:
    fig, axes = plt.subplots(1, 2, figsize=(12, 8 if name != 'firm_use' else 5.7))
    fig.subplots_adjust(left=.17, right=.97, top=.93, bottom=.15, wspace=.90)
    for ax, (key, title, xlabel) in zip(axes, panels):
        data = sorted(latest(key), key=lambda r: r['value'], reverse=True)
        assert any(r['country'] == 'France' for r in data)
        vals = [r['value'] for r in data]
        ax.barh(range(len(data)), vals, color=[MAROON if r['country'] == 'France' else NAVY for r in data],
                alpha=.8, height=.70, linewidth=.25)
        ax.set_yticks(range(len(data)), [f"{r['country']} ({r['year']})" for r in data])
        ax.invert_yaxis()
        ax.set_xlim(0, max(vals) * 1.19)
        ax.set_xlabel(xlabel)
        ax.set_title(title, pad=12)
        ax.grid(axis='x')
        ax.tick_params(axis='y', length=0)
        for i, (r, v) in enumerate(zip(data, vals)):
            ax.text(v + max(vals) * .018, i, f'{v:.1f}', va='center', fontsize=9)
            if r['country'] in ('France', 'United States'):
                ax.get_yticklabels()[i].set_fontweight('bold')
        plotted.extend(data)
    fig.legend(handles=[Patch(facecolor=MAROON, alpha=.8, label='France'),
                        Patch(facecolor=NAVY, alpha=.8, label='Other countries')],
               loc='lower center', bbox_to_anchor=(.5, .01), ncol=2)
    fig.savefig(HERE / f'{name}.pdf', bbox_inches='tight')
    plt.close(fig)

with (HERE / 'plotted_values.csv').open('w', newline='') as f:
    w = csv.DictWriter(f, fieldnames=list(plotted[0]))
    w.writeheader()
    w.writerows(plotted)
print(f'Wrote Figures D.1 to D.4 and {len(plotted)} plotted values to {HERE}')
