from math import ceil

# Constants
F_SIZE = 29 + 2  # Size of a single Forward TLV
RO_SIZE = 182 + 2  # Receive TLV size for Offer
RR_SIZE = 110 + 2  # Receive TLV size for Refund
P = list(range(30, 32))  # Range of padding values to test

def padding(size, p):
    """Calculate the padded size based on the specified padding value."""
    return ceil(size / p) * p

def color_code(value, min_value, max_value):
    """Apply grayscale color coding to the value based on its proximity to the minimum."""
    # Normalize the value to a 0-1 range
    normalized = (value - min_value) / (max_value - min_value) if max_value > min_value else 0
    # Map the normalized value to grayscale intensity
    intensity = int(255 * (1 - normalized))  # Brighter for values closer to the minimum
    return f"\033[38;2;{intensity};{intensity};{intensity}m{value}\033[0m"

def table_maker(r_size):
    """Generate and print a table showing the total sizes for various padding values."""
    # Prepare the header of the markdown table
    header = "| Number of Forward TLVs | " + " | ".join([f"Total Size (P={i})" for i in P]) + " |"
    separator = "|" + "|".join(["---"] * (len(P) + 1)) + "|"

    # Print header
    print(header)
    print(separator)

    # Generate and print rows for each multiple of F_SIZE
    for j in range(6):
        row = [f"{j}"]  # Start with the number of Forward TLVs
        sizes = [padding(r_size, i) + j * padding(F_SIZE, i) for i in P]
        min_size = min(sizes)
        max_size = max(sizes)

        # Add each size to the row, color-coded based on proximity to minimum
        for size in sizes:
            row.append(color_code(size, min_size, max_size))

        print("| " + " | ".join(row) + " |")

    print("\n")

if __name__ == "__main__":
    print("\n")
    print(f"For Offer: {RO_SIZE}\n")
    table_maker(RO_SIZE)
    print(f"For Refund: {RR_SIZE}\n\n")
    table_maker(RR_SIZE)
