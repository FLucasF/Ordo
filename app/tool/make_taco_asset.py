"""Writes assets/taco.json, the food table of the Dieta module, from the TACO CSV files.

Run from the app folder:  python tool/make_taco_asset.py <folder with taco.csv and medidas.csv>
  taco.csv: the Tabela Brasileira de Composição de Alimentos (TACO, NEPA/Unicamp, 4th edition), one food
  per row, values per 100 g of the edible part; an empty cell is "not measured" (kept as null, never 0).
  medidas.csv (codigo_taco, descricao, gramas, padrao): household measures of the TACO foods, weighed
  by the author (TACO publishes none).

Each food: [code, group, description, kcal, protein g, carbohydrate g, fat g, fiber g]; measures by code:
[[description, grams, default], ...].
"""
import csv
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def number(text: str):
    text = text.strip()
    return None if text == '' else round(float(text), 2)


def main() -> None:
    source = Path(sys.argv[1])
    foods = []
    with open(source / 'taco.csv', encoding='utf-8') as f:
        for row in csv.DictReader(f):
            foods.append([
                int(row['codigo']),
                row['grupo'].strip(),
                ' '.join(row['descricao'].split()),
                number(row['energia_kcal']),
                number(row['proteina_g']),
                number(row['carboidrato_g']),
                number(row['lipideos_g']),
                number(row['fibra_g']),
            ])
    measures: dict[str, list] = {}
    with open(source / 'medidas.csv', encoding='utf-8') as f:
        for row in csv.DictReader(f):
            measures.setdefault(row['codigo_taco'], []).append(
                [row['descricao'].strip(), number(row['gramas']), row['padrao'].strip().lower() == 'true']
            )
    out = {'source': 'TACO, NEPA/Unicamp, 4ª edição', 'foods': foods, 'measures': measures}
    target = ROOT / 'assets' / 'taco.json'
    target.write_text(json.dumps(out, ensure_ascii=False, separators=(',', ':')), encoding='utf-8')
    print(f'{len(foods)} foods, {sum(len(m) for m in measures.values())} measures -> {target}')


if __name__ == '__main__':
    main()
