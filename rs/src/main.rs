use genanki_rs::{Deck, Note, basic_model};
use scraper::{Html, Selector};
use std::{collections::HashMap, env::args, fs};

pub fn main() {
    let inpath = args().nth(1).expect("Usage: tanki-rs <input-html-file>");
    let html = fs::read_to_string(inpath).expect("Couldn't read file contents");

    let document = Html::parse_document(&html);
    let mut decks = parse_decks(&document);
    let mut notes = parse_notes(&document);

    for (id, deck) in decks.iter_mut() {
        println!("Adding deck {}", id);
        for note in notes.remove(id).unwrap() {
            println!("Adding note");
            deck.add_note(note);
        }
        deck.write_to_file(&(id.to_string() + ".apkg")).unwrap();
        println!("Wrote deck {}.apkg", id);
    }
}

pub fn parse_decks(document: &Html) -> HashMap<i64, Deck> {
    let deck_selector = Selector::parse("tanki-deck").unwrap();
    let desc_selector = Selector::parse("desc").unwrap();
    let name_selector = Selector::parse("name").unwrap();

    document
        .select(&deck_selector)
        .map(|deck| {
            let id = deck.value().attr("id").unwrap().parse::<i64>().unwrap();
            (
                id,
                Deck::new(
                    id,
                    &deck.select(&name_selector).next().unwrap().inner_html(),
                    &deck.select(&desc_selector).next().unwrap().inner_html(),
                ),
            )
        })
        .collect()
}

pub fn parse_notes(document: &Html) -> HashMap<i64, Vec<Note>> {
    let note_selector = Selector::parse("tanki-note").unwrap();
    let fields_selector = Selector::parse("fields ul li").unwrap();
    let deck_selector = Selector::parse("deck").unwrap();

    let mut res = HashMap::new();

    for (id, note) in document.select(&note_selector).map(|note| {
        let fields = note
            .select(&fields_selector)
            .map(|field| field.inner_html())
            .collect::<Vec<_>>();
        (
            note.select(&deck_selector)
                .next()
                .unwrap()
                .inner_html()
                .parse::<i64>()
                .unwrap(),
            Note::new(basic_model(), fields.iter().map(AsRef::as_ref).collect()).unwrap(),
        )
    }) {
        res.entry(id).or_insert_with(Vec::new).push(note);
    }

    res
}
