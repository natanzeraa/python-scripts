def load_suffixes(suffixes_path):
    with open(suffixes_path, "r") as f:
        suffixes = [line.strip().lower() for line in f if line.strip()]
    # Ordena do maior para o menor (para cortar primeiro os mais específicos)
    suffixes.sort(key=len, reverse=True)
    return suffixes


def sanitize(domain, suffixes):
    domain = domain.strip().lower()
    for suffix in suffixes:
        if domain.endswith(suffix):
            return domain[:-len(suffix)]
    return domain


def clean_domains(input_path, output_path, suffixes_path):
    suffixes = load_suffixes(suffixes_path)

    with open(input_path, "r") as f:
        domains = f.readlines()

    cleaned_domains = set()

    for domain in domains:
        sanitized = sanitize(domain, suffixes)
        cleaned_domains.add(sanitized)

    with open(output_path, "w") as f:
        for domain in sorted(cleaned_domains):
            f.write(domain + "\n")


input_path = "input/domains.txt"
output_path = "output/domains.txt"
suffixes_path = "input/suffixes.txt"
clean_domains(input_path, output_path, suffixes_path)
