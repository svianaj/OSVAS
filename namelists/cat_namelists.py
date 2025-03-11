import glob

def read_namelists(filenames):
    namelists = {}
    current_block = []
    current_name = None
    
    for filename in filenames:
        with open(filename, 'r') as f:
            for line in f:
                line = line.rstrip()

                if line.startswith('&'):
                    current_name = line.strip()
                    current_block = [line]  # Start a new namelist block
                elif line.startswith('/'):
                    if current_name:  # Ensure a valid block before storing
                        current_block.append(line)
                        namelists[current_name] = '\n'.join(current_block)
                    else:
                        print(f"Warning: Encountered '/' without a preceding '&' in {filename}")
                    current_block = []
                    current_name = None
                elif current_name:
                    current_block.append(line)

    return {k: v for k, v in namelists.items() if k}  # Remove any None keys

def write_sorted_namelists(namelists, output_file):
    with open(output_file, 'w') as f:
        for key in sorted(namelists.keys()):
            f.write(namelists[key] + '\n\n')

def main():
    input_files = sorted(glob.glob("OPTIONS*"))  # Find all matching files
    namelists = read_namelists(input_files)
    
    if not namelists:
        print("No valid namelists found.")
        return

    write_sorted_namelists(namelists, "sorted_namelist.txt")
    print("Sorted namelists written to sorted_namelist.txt")

if __name__ == "__main__":
    main()

