use genanki_rs::{Deck, Note, basic_model};
use scraper::{Html, Selector};
use std::{collections::HashMap, env::args, fs, path::Path, process::Command};
use tempfile::NamedTempFile;

pub fn main() {
    let html_file = args()
        .nth(1)
        .expect("Usage: tanki-rs <input-file> [output-path]");
    let output_arg = args().nth(2);
    let has_out_arg = output_arg.as_ref().is_some_and(|p| !p.starts_with("-"));
    let typst_args_from = if has_out_arg { 3 } else { 2 };
    let output_arg = output_arg.unwrap_or("".to_string());
    let output_path = if has_out_arg {
        Path::new(&output_arg)
    } else {
        Path::new(&html_file).parent().unwrap()
    };
    // TODO: compile using typst lib as soon as mathml is merged
    // then the whole html parsing step can be yeeted as well
    let input_html_path;
    if html_file.ends_with(".typ") {
        let tmpfile = NamedTempFile::new().expect("Couldn't create temp file");
        let tmppath = tmpfile.into_temp_path();

        input_html_path = tmppath
            .to_str()
            .expect("Temp file path not valid")
            .to_string();

        let status = Command::new("typst")
            .arg("compile")
            .args(args().skip(typst_args_from).collect::<Vec<_>>())
            .arg("--format=html")
            .arg("--features=html")
            .arg("--input=tanki=true")
            .arg(&html_file)
            .arg(&input_html_path)
            .status()
            .expect("Failed to compile document");

        assert!(status.success(), "Compilation wasn't successful");
    } else {
        input_html_path = html_file.clone();
    };
    do_the_thing(
        fs::read_to_string(&input_html_path).expect("Couldn't read file contents"),
        output_path,
    );
}

pub fn do_the_thing(html: String, output_path: &Path) {
    let document = Html::parse_document(&html);
    let mut decks = parse_decks(&document);
    let mut notes = parse_notes(&document);

    for (id, (filename, deck)) in decks.iter_mut() {
        println!("Adding deck {}", filename);
        for note in notes.remove(id).unwrap() {
            println!("Adding note");
            deck.add_note(note);
        }
        let output_path = output_path.join(&(filename.to_owned() + ".apkg"));
        let deck_path = output_path.to_str().unwrap();
        deck.write_to_file(deck_path).unwrap();
        println!("Wrote deck {}", deck_path);
    }
}

pub fn parse_decks(document: &Html) -> HashMap<i64, (String, Deck)> {
    let deck_selector = Selector::parse("tanki-deck").unwrap();
    let desc_selector = Selector::parse("desc").unwrap();
    let name_selector = Selector::parse("name").unwrap();
    let filename_selector = Selector::parse("filename").unwrap();

    document
        .select(&deck_selector)
        .map(|deck| {
            let id = deck.value().attr("id").unwrap().parse::<i64>().unwrap();
            (
                id,
                (
                    deck.select(&filename_selector).next().unwrap().inner_html(),
                    Deck::new(
                        id,
                        &deck.select(&name_selector).next().unwrap().inner_html(),
                        &deck.select(&desc_selector).next().unwrap().inner_html(),
                    ),
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
