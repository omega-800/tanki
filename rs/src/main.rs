use genanki_rs::{Deck, Note, basic_model};
use scraper::{Html, Selector};
use std::{
    collections::HashMap,
    env::args,
    fs,
    process::Command,
};
use tempfile::NamedTempFile;

pub fn main() {
    let html_file = args()
        .nth(1)
        .expect("Usage: tanki-rs <input-file> [output-path]");
    let output_path = args().nth(2);
    let typst_args_from = if output_path.is_some_and(|p| !p.starts_with("-")) {
        3
    } else {
        2
    };
    // TODO: compile using typst lib as soon as mathml is merged
    // then the whole html parsing step can be yeeted as well
    if html_file.ends_with(".typ") {
        let tmpfile = NamedTempFile::new().expect("Couldn't create temp file");
        let tmppath = tmpfile.into_temp_path();

        let out_file = tmppath
            .to_str()
            .expect("Temp file path not valid")
            .to_string();

        let status = Command::new("typst")
            .arg("compile")
            .args(args().skip(typst_args_from).collect::<Vec<_>>())
            .arg("--format=html")
            .arg("--features=html")
            .arg("--input=tanki=true")
            .arg(html_file)
            .arg(&out_file)
            .status()
            .expect("Failed to compile document");

        assert!(status.success(), "Compilation wasn't successful");

        do_the_thing(fs::read_to_string(out_file).expect("Couldn't read file contents"));
    } else {
        do_the_thing(fs::read_to_string(html_file).expect("Couldn't read file contents"));
    }
}

pub fn do_the_thing(html: String) {
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
