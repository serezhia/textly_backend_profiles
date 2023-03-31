CREATE TABLE
    "blacklist_user" (
        "requester_user_id" int8 NOT NULL,
        "blocked_user_id" int8 NOT NULL,
        "created_at" timestamp NOT NULL,
        CONSTRAINT "requster_blocked_user_id_un" UNIQUE (
            "requester_user_id",
            "blocked_user_id"
        )
    );

CREATE TABLE
    "profiles" (
        "user_id" int8 NOT NULL,
        "username" varchar(30) NOT NULL,
        "profile_name" varchar(50) NOT NULL,
        "description" varchar(255) NOT NULL,
        "avatar" varchar(10) NOT NULL,
        "background_color" varchar(8) NOT NULL,
        "created_at" timestamp NOT NULL,
        "is_premium" bool NOT NULL,
        "is_delete" bool NOT NULL,
        "following" int8 NOT NULL,
        "followers" int8 NOT NULL,
        PRIMARY KEY ("user_id"),
        CONSTRAINT "username_un" UNIQUE ("username")
    );

CREATE TABLE
    "user_relationships" (
        "publishing_user_id" int8 NOT NULL,
        "reading_user_id" int8 NOT NULL,
        "created_at" timestamp NOT NULL,
        CONSTRAINT "un_reading_publishing" UNIQUE (
            "publishing_user_id",
            "reading_user_id"
        )
    );

ALTER TABLE "blacklist_user"
ADD
    CONSTRAINT "requester_user_id" FOREIGN KEY ("requester_user_id") REFERENCES "profiles" ("user_id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "blacklist_user"
ADD
    CONSTRAINT "blocked_user_id" FOREIGN KEY ("blocked_user_id") REFERENCES "profiles" ("user_id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE
    "user_relationships"
ADD
    CONSTRAINT "publishing_user_id_fk" FOREIGN KEY ("publishing_user_id") REFERENCES "profiles" ("user_id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE
    "user_relationships"
ADD
    CONSTRAINT "reading_user_id" FOREIGN KEY ("reading_user_id") REFERENCES "profiles" ("user_id") ON DELETE CASCADE ON UPDATE CASCADE;