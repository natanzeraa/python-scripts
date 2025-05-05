def clean_domains(input_path, output_path):
    with open(input_path, "r") as f:
        domains = f.readlines()

    domain_set = set()

    for domain in domains:
        domain = domain.strip().lower()
        domain_set.add(domain)

    with open(output_path, "w") as f:
        for domain in sorted(domain_set):
            f.write(domain + "\n")


input = "input/domains.txt"
output = "output/domains.txt"
clean_domains(input, output)
