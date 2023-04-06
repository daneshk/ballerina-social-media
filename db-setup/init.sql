DROP DATABASE if exists social_media_database;

CREATE DATABASE social_media_database;

USE social_media_database;

CREATE TABLE users (
    `id` INT NOT NULL auto_increment PRIMARY KEY,
    `birth_date` DATE,
    name VARCHAR(255)
);
CREATE TABLE posts (
    id INT NOT NULL auto_increment PRIMARY KEY,
    description VARCHAR(255),
    category VARCHAR(255),
    created_date DATE,
    tags VARCHAR(255),
    user_id INT
);
ALTER TABLE posts ADD FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE users ADD mobile_number VARCHAR(15) NOT NULL;

INSERT INTO users (
        id,
        birth_date,
        name,
        mobile_number
    )
VALUES (
        1,
        Curdate(),
        "ranga",
        "+94771234001"
    );
INSERT INTO users (
        id,
        birth_date,
        name,
        mobile_number
    )
VALUES (
        2,
        Curdate(),
        "ravi",
        "+94771234002"
    );
INSERT INTO users (
        id,
        birth_date,
        name,
        mobile_number
    )
VALUES (
        3,
        Curdate(),
        "satish",
        "+94771234001"
    );
INSERT INTO users (
        id,
        birth_date,
        name,
        mobile_number
    )
VALUES (
        4,
        Curdate(),
        "ayesh",
        "+94768787189"
    );
INSERT INTO posts (
        description,
        category,
        created_date,
        tags,
        user_id
    )
VALUES (
        'I want to learn AWS',
        'education',
        Curdate(),
        'aws,cloud,learn',
        1
    );
INSERT INTO posts (
        description,
        category,
        created_date,
        tags,
        user_id
    )
VALUES (
        'I want to learn DevOps',
        'education',
        Curdate(),
        'devops,infra,learn',
        1
    );
INSERT INTO posts (
        description,
        category,
        created_date,
        tags,
        user_id
    )
VALUES (
        'I want to learn GCP',
        'education',
        Curdate(),
        'gcp,google,learn',
        2
    );
INSERT INTO posts (
        description,
        category,
        created_date,
        tags,
        user_id
    )
VALUES (
        'I want to learn multi cloud',
        'education',
        Curdate(),
        'gcp,aws,azure,infra,learn',
        3
    );
CREATE TABLE followers (
    id INT NOT NULL auto_increment PRIMARY KEY,
    created_date DATE,
    leader_id INT,
    follower_id INT,
    UNIQUE (leader_id, follower_id),
    FOREIGN KEY (leader_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (follower_id) REFERENCES users(id) ON DELETE CASCADE
);
INSERT INTO followers (
        created_date,
        leader_id,
        follower_id
    )
VALUES (Curdate(), 1, 4);

CREATE PROCEDURE get_posts_for_user(IN user_id INT, OUT postCount INT)
BEGIN
    SELECT COUNT(*) INTO postCount FROM posts WHERE user_id = user_id;

    SELECT user.name, post.description, post.category, post.created_date
    FROM posts post
    INNER JOIN users user ON user.id = post.user_id
    WHERE post.user_id = user_id;
END;

