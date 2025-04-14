import argparse
from PyPDF2 import PdfMerger


"""
Este script serve para unir múltiplos arquivos PDF em um único documento.

### Como usar:

    python merge_pdf.py -i input/00.pdf input/01.pdf input/02.pdf -o output/arquivo_final.pdf

Parâmetros:
    -i ou --input    : Lista de arquivos PDF a serem unidos (em ordem).
    -o ou --output   : Caminho e nome do arquivo PDF de saída.

Certifique-se de que:
    - Os arquivos de entrada existem.
    - O diretório de saída também existe (senão, o script pode falhar).
"""


def merge_pdf(pdf_file_list, output_filename):
    merger = PdfMerger()
    for pdf in pdf_file_list:
        merger.append(pdf)
    merger.write(output_filename)
    merger.close()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Merge multiple PDF files into one.")

    parser.add_argument(
        "-i", "--input", nargs="+", required=True,
        help="Lista de arquivos PDF para juntar (em ordem)"
    )
    parser.add_argument(
        "-o", "--output", required=True,
        help="Nome do arquivo PDF de saída (ex: output/arquivo_final.pdf)"
    )

    args = parser.parse_args()

    merge_pdf(args.input, args.output)
