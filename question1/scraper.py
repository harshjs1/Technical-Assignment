#!/usr/bin/env python3
"""Extract product names and selling prices from MDComputers search results."""

from __future__ import annotations

import sys
from urllib.parse import quote_plus

import cloudscraper
from bs4 import BeautifulSoup

BASE_URL = "https://mdcomputers.in/index.php"
SEARCH_ROUTE = "product/search"
REQUEST_TIMEOUT = 30


def build_search_url(search_term: str) -> str:
    """Build the MDComputers search URL for a given term."""
    encoded_term = quote_plus(search_term.strip())
    return f"{BASE_URL}?route={SEARCH_ROUTE}&search={encoded_term}"


def fetch_search_page(search_term: str) -> str:
    """Fetch the HTML for a product search page."""
    url = build_search_url(search_term)
    scraper = cloudscraper.create_scraper(
        browser={"browser": "chrome", "platform": "windows", "mobile": False}
    )
    response = scraper.get(url, timeout=REQUEST_TIMEOUT)
    response.raise_for_status()
    return response.text


def extract_selling_price(product_element) -> str | None:
    """Return the current selling price from a product card."""
    discounted_price = product_element.select_one(".price .ins .amount")
    if discounted_price:
        return discounted_price.get_text(strip=True)

    price_container = product_element.select_one(".price")
    if not price_container:
        return None

    # Products without a discount expose a single price amount.
    for amount in price_container.select(".amount"):
        if amount.find_parent(class_="del"):
            continue
        text = amount.get_text(strip=True)
        if text:
            return text

    return price_container.get_text(" ", strip=True) or None


def parse_products(html: str) -> list[dict[str, str]]:
    """Parse product cards from the search results page."""
    soup = BeautifulSoup(html, "html.parser")
    products: list[dict[str, str]] = []

    for item in soup.select(".product-grid-item"):
        name_element = item.select_one("h3.product-entities-title a")
        if not name_element:
            continue

        name = name_element.get_text(strip=True)
        price = extract_selling_price(item)
        if not name or not price:
            continue

        products.append({"name": name, "price": price})

    return products


def display_products(products: list[dict[str, str]], search_term: str) -> None:
    """Print products in a readable table format."""
    if not products:
        print(f"No products found for search term: {search_term}")
        return

    print(f"\nProducts found for '{search_term}':\n")
    print(f"{'#':<4} {'Product Name':<60} {'Selling Price':<15}")
    print("-" * 81)

    for index, product in enumerate(products, start=1):
        print(f"{index:<4} {product['name']:<60} {product['price']:<15}")

    print(f"\nTotal products: {len(products)}")


def main() -> int:
    """Run the scraper from user input."""
    try:
        search_term = input("Enter search term: ").strip()
    except EOFError:
        print("Error: No search term provided.", file=sys.stderr)
        return 1

    if not search_term:
        print("Error: Search term cannot be empty.", file=sys.stderr)
        return 1

    try:
        html = fetch_search_page(search_term)
        products = parse_products(html)
    except Exception as exc:
        print(f"Error: Failed to retrieve or parse search results ({exc}).", file=sys.stderr)
        return 1

    display_products(products, search_term)
    return 0


if __name__ == "__main__":
    sys.exit(main())
