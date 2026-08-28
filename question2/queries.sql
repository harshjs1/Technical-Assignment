-- Question 2A
-- Count how many distinct Acacia plant types exist in the taxonomy table.
-- Genus Acacia is identified by the taxonomic string ending with "; Acacia."
SELECT COUNT(DISTINCT species) AS acacia_plant_types
FROM taxonomy
WHERE tax_string LIKE '%; Acacia.';


-- Question 2B
-- Find the wheat type with the longest DNA sequence.
-- Wheat species belong to genus Triticum in the taxonomy table.
SELECT
    t.species AS wheat_type,
    rs.length AS dna_sequence_length
FROM rfamseq AS rs
INNER JOIN taxonomy AS t ON rs.ncbi_id = t.ncbi_id
WHERE t.tax_string LIKE '%; Triticum.'
ORDER BY rs.length DESC
LIMIT 1;


-- Question 2C
-- List families with maximum DNA sequence length greater than 1,000,000,
-- sorted by length descending, returning page 9 (rows 121-135).
SELECT
    f.rfam_acc AS family_accession,
    f.rfam_id AS family_name,
    family_lengths.max_dna_sequence_length
FROM (
    SELECT
        fr.rfam_acc,
        MAX(rs.length) AS max_dna_sequence_length
    FROM full_region AS fr
    INNER JOIN rfamseq AS rs ON fr.rfamseq_acc = rs.rfamseq_acc
    GROUP BY fr.rfam_acc
    HAVING MAX(rs.length) > 1000000
) AS family_lengths
INNER JOIN family AS f ON f.rfam_acc = family_lengths.rfam_acc
ORDER BY family_lengths.max_dna_sequence_length DESC
LIMIT 15 OFFSET 120;
