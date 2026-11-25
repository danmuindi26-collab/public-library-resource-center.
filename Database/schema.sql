
CREATE DATABASE IF NOT EXISTS public_library
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE public_library;

-- -----------------------------------------------------
-- Users: everyone who can log in (librarian or member)
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
    user_id       INT AUTO_INCREMENT PRIMARY KEY,
    username      VARCHAR(50)  NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    full_name     VARCHAR(100) NOT NULL,
    email         VARCHAR(100) UNIQUE,
    role          ENUM('Librarian','Member') NOT NULL,
    is_active     TINYINT(1) NOT NULL DEFAULT 1,
    created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- Members: library details for users with role 'Member'
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS members (
    member_id     INT AUTO_INCREMENT PRIMARY KEY,
    user_id       INT NOT NULL UNIQUE,
    membership_no VARCHAR(20) NOT NULL UNIQUE,
    phone         VARCHAR(20),
    address       VARCHAR(150),
    join_date     DATE NOT NULL,
    status        ENUM('Active','Suspended','Expired') NOT NULL DEFAULT 'Active',
    CONSTRAINT fk_members_user FOREIGN KEY (user_id)
        REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- Categories and books
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS categories (
    category_id   INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(60) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS books (
    book_id          INT AUTO_INCREMENT PRIMARY KEY,
    isbn             VARCHAR(20) UNIQUE,
    title            VARCHAR(150) NOT NULL,
    author           VARCHAR(100) NOT NULL,
    publisher        VARCHAR(100),
    publish_year     YEAR,
    category_id      INT,
    total_copies     INT NOT NULL DEFAULT 1,
    available_copies INT NOT NULL DEFAULT 1,
    added_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_books_category FOREIGN KEY (category_id)
        REFERENCES categories(category_id) ON DELETE SET NULL,
    CONSTRAINT chk_copies CHECK (
        available_copies >= 0 AND available_copies <= total_copies
    )
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- Loans: issue and return
-- status is 'Issued' until the book comes back
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS loans (
    loan_id     INT AUTO_INCREMENT PRIMARY KEY,
    book_id     INT NOT NULL,
    member_id   INT NOT NULL,
    issued_by   INT NOT NULL,              -- librarian's user_id
    issue_date  DATE NOT NULL,
    due_date    DATE NOT NULL,
    return_date DATE NULL,
    status      ENUM('Issued','Returned') NOT NULL DEFAULT 'Issued',
    CONSTRAINT fk_loans_book   FOREIGN KEY (book_id)   REFERENCES books(book_id),
    CONSTRAINT fk_loans_member FOREIGN KEY (member_id) REFERENCES members(member_id),
    CONSTRAINT fk_loans_staff  FOREIGN KEY (issued_by) REFERENCES users(user_id)
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- Fines for late returns (one fine per late loan)
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS fines (
    fine_id   INT AUTO_INCREMENT PRIMARY KEY,
    loan_id   INT NOT NULL UNIQUE,
    member_id INT NOT NULL,
    days_late INT NOT NULL,
    amount    DECIMAL(10,2) NOT NULL,
    is_paid   TINYINT(1) NOT NULL DEFAULT 0,
    paid_date DATE NULL,
    CONSTRAINT fk_fines_loan   FOREIGN KEY (loan_id)   REFERENCES loans(loan_id),
    CONSTRAINT fk_fines_member FOREIGN KEY (member_id) REFERENCES members(member_id)
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- Reservations (nice to have): hold a book that is out
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS reservations (
    reservation_id INT AUTO_INCREMENT PRIMARY KEY,
    book_id        INT NOT NULL,
    member_id      INT NOT NULL,
    reserved_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status         ENUM('Waiting','Ready','Fulfilled','Cancelled') NOT NULL DEFAULT 'Waiting',
    CONSTRAINT fk_res_book   FOREIGN KEY (book_id)   REFERENCES books(book_id),
    CONSTRAINT fk_res_member FOREIGN KEY (member_id) REFERENCES members(member_id)
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- Settings: change loan rules without editing code
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS settings (
    setting_key   VARCHAR(50) PRIMARY KEY,
    setting_value VARCHAR(50) NOT NULL
) ENGINE=InnoDB;

INSERT IGNORE INTO settings (setting_key, setting_value) VALUES
    ('loan_days', '14'),
    ('fine_per_day', '10.00'),
    ('max_active_loans', '3');

-- -----------------------------------------------------
-- View: most borrowed books (nice to have)
-- -----------------------------------------------------
CREATE OR REPLACE VIEW v_most_borrowed AS
SELECT b.book_id, b.title, b.author, COUNT(l.loan_id) AS times_borrowed
FROM books b
JOIN loans l ON l.book_id = b.book_id
GROUP BY b.book_id, b.title, b.author
ORDER BY times_borrowed DESC;

-- -----------------------------------------------------
-- Helpful indexes
-- -----------------------------------------------------
CREATE INDEX idx_books_title  ON books(title);
CREATE INDEX idx_loans_member ON loans(member_id, status);
CREATE INDEX idx_loans_book   ON loans(book_id, status);
