-- =====================================================
-- Sample data for testing ONLY. Run after schema.sql.
-- Test passwords are hashed with SHA2 so they are not plain text.
-- Logins:  librarian1 / Admin@123     member1 / Member@123
-- =====================================================

USE public_library;

INSERT INTO users (username, password_hash, full_name, email, role) VALUES
    ('librarian1', SHA2('Admin@123', 256),  'Main Librarian', 'librarian@library.test', 'Librarian'),
    ('member1',    SHA2('Member@123', 256), 'Test Member',    'member1@library.test',   'Member');

INSERT INTO members (user_id, membership_no, phone, join_date)
SELECT user_id, 'LIB-0001', '0700000000', CURDATE()
FROM users WHERE username = 'member1';

INSERT INTO categories (category_name) VALUES
    ('Fiction'), ('Science'), ('Technology'), ('History'), ('Reference');

INSERT INTO books (isbn, title, author, publisher, publish_year, category_id, total_copies, available_copies)
VALUES
    ('9780140328721', 'Matilda',                  'Roald Dahl',      'Puffin',     1988, 1, 3, 3),
    ('9780262033848', 'Introduction to Algorithms','Thomas Cormen',  'MIT Press',  2009, 3, 2, 2),
    ('9780393355628', 'Sapiens',                  'Yuval Noah Harari','Harper',    2015, 4, 2, 2),
    ('9780553380163', 'A Brief History of Time',  'Stephen Hawking', 'Bantam',     1998, 2, 1, 1);
