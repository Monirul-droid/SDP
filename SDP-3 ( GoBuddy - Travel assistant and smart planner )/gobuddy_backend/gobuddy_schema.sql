BEGIN TRANSACTION;
CREATE TABLE IF NOT EXISTS avatars (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            avatar_name TEXT NOT NULL,
            avatar_link TEXT NOT NULL UNIQUE
        );
CREATE TABLE IF NOT EXISTS expenses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT NOT NULL,
            title TEXT NOT NULL,
            amount REAL NOT NULL,
            FOREIGN KEY (email) REFERENCES users (email)
        );
CREATE TABLE IF NOT EXISTS favourites (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_email TEXT NOT NULL,
            location_id INTEGER NOT NULL,
            name TEXT NOT NULL,
            location TEXT,
            category TEXT,
            image_url TEXT,
            description TEXT
        );
CREATE TABLE IF NOT EXISTS itineraries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_email TEXT NOT NULL,
            trip_name TEXT,
            destination TEXT,
            day TEXT,
            activity TEXT,
            cost TEXT
        );
CREATE TABLE IF NOT EXISTS locations (
            location_id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            location_address TEXT,
            category TEXT,
            image_url TEXT,
            description TEXT,
            rating REAL DEFAULT 0.0
        );
CREATE TABLE IF NOT EXISTS tour_packages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            city TEXT UNIQUE NOT NULL,
            hotel TEXT,
            budget TEXT,
            places TEXT,
            restaurants TEXT,
            travel_way TEXT,
            image_url TEXT
        );
CREATE TABLE IF NOT EXISTS user_avatars (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT UNIQUE NOT NULL,
            avatar_id INTEGER NOT NULL,
            FOREIGN KEY (email) REFERENCES users (email),
            FOREIGN KEY (avatar_id) REFERENCES avatars (id)
        );
CREATE TABLE IF NOT EXISTS user_names (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT UNIQUE NOT NULL,
            first_name TEXT DEFAULT '',
            last_name TEXT DEFAULT '',
            FOREIGN KEY (email) REFERENCES users (email)
        );
CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT UNIQUE NOT NULL,
            password TEXT NOT NULL
        );
INSERT INTO "avatars" ("id","avatar_name","avatar_link") VALUES (1,'Avatar1','https://img.freepik.com/free-psd/3d-illustration-with-online-avatar_23-2151303097.jpg?semt=ais_hybrid&w=740&q=80'),
 (2,'Avatar2','https://img.freepik.com/free-vector/smiling-redhaired-boy-illustration_1308-176664.jpg?semt=ais_hybrid&w=740&q=80'),
 (3,'Avatar3','https://cdn.soft112.com/cartoon-maker-avatar-creator-anime/00/00/0H/DU/00000HDUTI/pad_screenshot.jpg'),
 (4,'Avatar4','https://img.freepik.com/premium-vector/flat-illustration-men-wearing-jacket-brown-black-color-combination_981536-1552.jpg?semt=ais_hybrid&w=740&q=80'),
 (5,'Avatar5','https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRuguVHs_II-hfOVQq1lHFpbDfJIWPnpDDgtg&s'),
 (6,'Avatar6','https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQ_ZSO2tXGKf88S7fxc9js8XAyMMpei6v518w&s');
INSERT INTO "expenses" ("id","email","title","amount") VALUES (4,'nasir1@gmail.com','bus fair',100.0),
 (5,'nasir1@gmail.com','hotel',200.0);
INSERT INTO "favourites" ("id","user_email","location_id","name","location","category","image_url","description") VALUES (7,'siam123@gmail.com',1,'Sajek Valley','Rangamati','Hill','https://bdsearcher.com/wp-content/uploads/2017/12/Sajek-Valley.jpg','Sajek Valley is a popular tourist spot. 
Estimated Value: 10000-15000 BDT');
INSERT INTO "itineraries" ("id","user_email","trip_name","destination","day","activity","cost") VALUES (1,'siam123@gmail.com','Trip 10-Apr','Bangladesh Tour','1','Cox''s Bazar','80.0'),
 (2,'siam123@gmail.com','Trip 10-Apr','Bangladesh Tour','2','Sundarbans','70.0'),
 (3,'siam.dcc2231@gmail.com','Trip 14-Apr','Bangladesh Tour','1','Dhaka','500.0'),
 (4,'siam.dcc2231@gmail.com','Trip 14-Apr','Bangladesh Tour','2','Cox''s Bazar','600.0'),
 (5,'siam.dcc2231@gmail.com','Trip 14-Apr','Bangladesh Tour','3','Sajek Valley','700.0'),
 (6,'siam.dcc2231@gmail.com','Trip 14-Apr','Bangladesh Tour','4','puran dhaka','600.0'),
 (17,'nasir1@gmail.com','Trip 17-Apr','Bangladesh Tour','1','Sajek Valley','100.0'),
 (18,'nasir1@gmail.com','Trip 17-Apr','Bangladesh Tour','2','Cox''s Bazar','200.0'),
 (19,'nasir1@gmail.com','Trip 17-Apr','Bangladesh Tour','3','Dhaka','500.0'),
 (20,'nasir1@gmail.com','Trip 17-Apr','Bangladesh Tour','4','Mirpur','100.0');
INSERT INTO "locations" ("location_id","name","location_address","category","image_url","description","rating") VALUES (1,'Sajek Valley','Rangamati','Hill','https://bdsearcher.com/wp-content/uploads/2017/12/Sajek-Valley.jpg','Sajek Valley is a popular tourist spot. 
Estimated Value: 10000-15000 BDT',0.0),
 (2,'Cox''s Bazar','Chittagong','Beach','https://www.laurewanders.com/wp-content/uploads/2023/02/Things-to-do-in-Coxs-Bazar-33.jpg','Cox’s Bazar is a town on the southeast coast of Bangladesh. It’s known for its very long, sandy beachfront, stretching from Sea Beach in the north to Kolatoli Beach in the south. Aggameda Khyang monastery is home to bronze statues and centuries-old Buddhist manuscripts. South of town, the tropical rainforest of Himchari National Park has waterfalls and many birds. North, sea turtles breed on nearby Sonadia Island.
Estimated Value: 5000-10000 BDT',0.0),
 (3,'Dhaka','Bangladesh','City','https://images.adsttc.com/media/images/52b0/93a8/e8e4/4e04/e300/003e/large_jpg/louis_kahn.jpg?1387303844','Dhaka, formerly known as Dacca, is the capital and largest city of Bangladesh. With an estimated population of 36.6 million, Dhaka is the second largest city by population in the world, and is widely considered to be the most densely populated built-up urban area in the world.
Estimated Value: 8000-13000 BDT',0.0),
 (4,'Puthia Rajbari','Rajshahi','Historical place','https://vromonguide.com/wp-content/uploads/puthia-rajbari-rajshahi.jpg','Puthia Rajbari is a palace in Puthia Upazila, Rajshahi District in Bangladesh. It was built in 1895, by Maharani Hemanta Kumari Devi in the memory of her mother-in-law Maharani Saratsundari Devi, it is an example of Indo-Saracenic Revival architecture.
Estimated Value: 5000-8000 BDT',0.0),
 (5,'Sundarbans','Khulna','Forest','https://imgs.mongabay.com/wp-content/uploads/sites/20/2017/10/06125834/Sundarban-tiger.jpg','Sundarbans is a mangrove forest area in the Ganges Delta formed by the confluence of the Ganges, Brahmaputra and Meghna Rivers in the Bay of Bengal. It spans the area from the Hooghly River in India''s state of West Bengal to the Baleswar River in Bangladesh''s Khulna Division.
Estimated Value: 9500-17000 BDT',0.0),
 (6,'Old Dhaka','Bangladesh','City','https://vromonguide.com/wp-content/uploads/tourist-attractions-in-old-dhaka.jpg','Lively Old Dhaka is known for historic buildings like the Mughal-era Lalbagh Fort, set amid green lawns, and Dhakeshwari Mandir, a 12th-century Hindu temple. Period furnishings are on display at the Ahsan Manzil Museum, a vast palace with a pink facade. Street vendors sell breads and sweets, while Shankhari Bazar is a popular spot to find bangles, spices, and textiles. River boat trips depart from the Sadarghat area. 
Estimated Value: 3500-7000 BDT',0.0);
INSERT INTO "tour_packages" ("id","city","hotel","budget","places","restaurants","travel_way","image_url") VALUES (1,'Dhaka','Pan Pacific Sonargaon','12,000 BDT','Lalbagh Fort, Ahsan Manzil','Star Kabab, Sultan''s Dine','Bus, Train, Air','https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQdNlv2UHIARVpZaiOxQ4S2GgVw3Mel4Ca2Zg&s'),
 (2,'Chittagong','Radisson Blu','20,000 BDT','Patenga Beach, Foy''s Lake','Mezban Haile Ayun, Barcode Cafe','Bus, Train, Air','https://bdscenictours.b-cdn.net/wp-content/uploads/2024/05/Blog-Post-2.jpg'),
 (3,'Rajshahi','Parjatan Motel','10,000 BDT','Padma Garden, Varendra Museum','Chillies, Master Chef','Bus, Train','https://i.ytimg.com/vi/aW-NRAJyyq8/maxresdefault.jpg'),
 (4,'Sylhet','Grand Sylhet','18,000 BDT','Ratargul, Jaflong','Pach Bhai, Woondaal','Bus, Train, Air','https://www.visit-bangladesh.net/wp-content/uploads/2025/05/Sylhet-Title-Image-copy1.jpg'),
 (5,'Cox''s Bazar','Sayeman Beach Resort','25,000 BDT','Inani Beach, Himchari','Poushee, Jhawban','Bus, Air','https://i.ytimg.com/vi/Eda5GhYk5pQ/maxresdefault.jpg'),
 (6,'Barisal','Hotel Grand Park','9,000 BDT','Floating Guava Market, Kuakata','Garden Rose, Sky View','Bus, Launch','https://i.ytimg.com/vi/vsCTBj2D5Mw/hq720.jpg?sqp=-oaymwEhCK4FEIIDSFryq4qpAxMIARUAAAAAGAElAADIQj0AgKJD&rs=AOn4CLALLOen_tzIWN1BF-cvJcgW2Vt5Ug'),
 (7,'Rangamati','Parjatan Holiday Complex','11,000 BDT','Kaptai Lake, Shuvolong Falls','Peda Ting Ting, Lake View','Bus','https://i.ytimg.com/vi/b2rNiy6AG0w/hq720.jpg?sqp=-oaymwEhCK4FEIIDSFryq4qpAxMIARUAAAAAGAElAADIQj0AgKJD&rs=AOn4CLCM0LQF4ccPuXaJ4a5XxkNM52vj9g'),
 (8,'Khulna','City Inn','14,000 BDT','Sundarbans, Shat Gombuj Masjid','Mezban Bari, Castle Salam','Bus, Train','https://i.ytimg.com/vi/7VtKI_XhNPE/hq720.jpg?sqp=-oaymwEhCK4FEIIDSFryq4qpAxMIARUAAAAAGAElAADIQj0AgKJD&rs=AOn4CLAbBD00OjT887RjTkwnqMNjkuf08A');
INSERT INTO "user_avatars" ("id","email","avatar_id") VALUES (1,'siam123@gmail.com',2),
 (3,'nasir1@gmail.com',2),
 (5,'siam.dcc2231@gmail.com',4);
INSERT INTO "user_names" ("id","email","first_name","last_name") VALUES (1,'nasir1@gmail.com','Nasir ','siam'),
 (3,'siam123@gmail.com','go','j'),
 (10,'siam.dcc2231@gmail.com','Al','Nasir');
INSERT INTO "users" ("id","email","password") VALUES (1,'siam123@gmail.com','$2b$12$WCR625F9am0aNp1PXQy/he.6hd4m56/oJSeOB4VPDBsB1XeHlOBJi'),
 (2,'siam.dcc2231@gmail.com','$2b$12$w/xJkGAUy7dpo0hm7RDILetXuu1Pi1ye2d0sQnwczTBKkn3ZJl/nS'),
 (3,'nasir1@gmail.com','$2b$12$qBEY6Sn7Jn4AAlxkd0m9HeFbjqor/KJD9wtlmeDKECpuyajmv2oq2');
COMMIT;
