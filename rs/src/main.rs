use genanki_rs::{Deck, Field, Model, ModelType, Note, Template, basic_model};
use scraper::{ElementRef, Html, Selector};
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
    if html_file.ends_with(".typ") {
        let tmpfile = NamedTempFile::new().expect("Couldn't create temp file");
        let tmppath = tmpfile.into_temp_path();

        let input_html_path = tmppath
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

        do_the_thing(
            fs::read_to_string(&input_html_path).expect("Couldn't read file contents"),
            output_path,
        );
    } else {
        do_the_thing(
            fs::read_to_string(&html_file).expect("Couldn't read file contents"),
            output_path,
        );
    };
}

pub fn do_the_thing(html: String, output_path: &Path) {
    let document = Html::parse_document(&html);
    let mut decks = parse_decks(&document);
    let mut notes = parse_notes(&document);

    for (id, (filename, deck)) in decks.iter_mut() {
        let Some(deck_notes) = notes.remove(id) else {
            continue;
        };
        println!("Adding deck \"{}\"", filename);
        let cnt = deck_notes.len();
        for note in deck_notes {
            deck.add_note(note);
        }
        println!("Added {} notes to \"{}\"", cnt, filename);
        let output_path = output_path.join(&(filename.to_owned() + ".apkg"));
        let deck_path = output_path.to_str().unwrap();
        deck.write_to_file(deck_path).unwrap();
        println!("Wrote deck {}", deck_path);
    }
}

// TODO: package

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
    // eh
    let models = parse_models(document);

    let note_selector = Selector::parse("tanki-note").unwrap();
    let fields_selector = Selector::parse("fields > ul > li.tanki-note").unwrap();
    let deck_selector = Selector::parse("deck").unwrap();
    let model_selector = Selector::parse("model > div > id").unwrap();
    let sf_selector = Selector::parse("sort-field").unwrap();
    let tags_selector = Selector::parse("tags > ul > li").unwrap();
    let guid_selector = Selector::parse("guid").unwrap();

    let mut res = HashMap::new();

    for (id, note) in document.select(&note_selector).map(|note| {
        let fields = note
            .select(&fields_selector)
            .map(|field| field.inner_html())
            .collect::<Vec<_>>();
        let tags = note
            .select(&tags_selector)
            .map(|tag| tag.inner_html())
            .collect::<Vec<_>>();
        let sort_field = note.select(&sf_selector).next().unwrap().inner_html();
        let guid = note.select(&guid_selector).next().unwrap().inner_html();
        let mid = note
            .select(&model_selector)
            .next()
            .map(|m| m.inner_html().parse::<i64>().unwrap());
        (
            note.select(&deck_selector)
                .next()
                .unwrap()
                .inner_html()
                .parse::<i64>()
                .unwrap(),
            Note::new_with_options(
                if let Some(mid) = mid {
                    models.get(&mid).unwrap().clone()
                } else {
                    basic_model()
                },
                fields.iter().map(AsRef::as_ref).collect(),
                sort_field.parse::<bool>().ok(),
                Some(tags.iter().map(AsRef::as_ref).collect()),
                // TODO:
                Some(&guid),
            )
            .unwrap(),
        )
    }) {
        res.entry(id).or_insert_with(Vec::new).push(note);
    }

    res
}

pub fn parse_models(document: &Html) -> HashMap<i64, Model> {
    let model_selector = Selector::parse("tanki-note > model > div").unwrap();
    let type_selector = Selector::parse("model-type").unwrap();
    let id_selector = Selector::parse("id").unwrap();
    let name_selector = Selector::parse("name").unwrap();
    let css_selector = Selector::parse("css").unwrap();
    let latex_pre_selector = Selector::parse("latex-pre").unwrap();
    let latex_post_selector = Selector::parse("latex-post").unwrap();
    let sf_selector = Selector::parse("sort-field-index").unwrap();

    let mut res = HashMap::new();

    for model in document.select(&model_selector) {
        let id = model
            .select(&id_selector)
            .next()
            .unwrap()
            .inner_html()
            .parse::<i64>()
            .unwrap();
        if res.contains_key(&id) {
            continue;
        }
        let name = model.select(&name_selector).next().unwrap().inner_html();
        let css = model.select(&css_selector).next().unwrap().inner_html();
        let model_type = model.select(&type_selector).next().unwrap().inner_html();
        let latex_pre = model
            .select(&latex_pre_selector)
            .next()
            .unwrap()
            .inner_html();
        let latex_post = model
            .select(&latex_post_selector)
            .next()
            .unwrap()
            .inner_html();
        let sort_field_index = model
            .select(&sf_selector)
            .next()
            .unwrap()
            .inner_html()
            .parse::<i64>();

        res.insert(
            id,
            Model::new_with_options(
                id,
                &name,
                parse_fields(&model),
                parse_templates(&model),
                Some(&css),
                Some(if model_type == "Cloze" {
                    ModelType::Cloze
                } else {
                    ModelType::FrontBack
                }),
                Some(&latex_pre),
                Some(&latex_post),
                sort_field_index.ok(),
            ),
        );
    }

    res
}

pub fn parse_fields(model: &ElementRef) -> Vec<Field> {
    let field_selector = Selector::parse("div > fields > ul > li > div.tanki-field").unwrap();
    let name_selector = Selector::parse("name").unwrap();
    let font_selector = Selector::parse("font").unwrap();
    let rtl_selector = Selector::parse("rtl").unwrap();
    let sticky_selector = Selector::parse("sticky").unwrap();
    let size_selector = Selector::parse("size").unwrap();

    model
        .select(&field_selector)
        .map(|field| {
            let name = field.select(&name_selector).next().unwrap().inner_html();
            let font = field.select(&font_selector).next().unwrap().inner_html();
            let rtl = field.select(&rtl_selector).next().unwrap().inner_html();
            let sticky = field.select(&sticky_selector).next().unwrap().inner_html();
            let size = field
                .select(&size_selector)
                .next()
                .unwrap()
                .inner_html()
                .parse::<i64>()
                .unwrap();

            Field::new(&name)
                .font(&font)
                .rtl(rtl == "true")
                .sticky(sticky == "true")
                .size(size)
        })
        .collect()
}

pub fn parse_templates(model: &ElementRef) -> Vec<Template> {
    let template_selector = Selector::parse("div > templates > ul > li > div").unwrap();

    let name_selector = Selector::parse("name").unwrap();
    let qfmt_selector = Selector::parse("question").unwrap();
    let afmt_selector = Selector::parse("answer").unwrap();
    let bqfmt_selector = Selector::parse("b-question").unwrap();
    let bafmt_selector = Selector::parse("b-answer").unwrap();

    // TODO: did
    // let did_selector = Selector::parse("").unwrap();

    model
        .select(&template_selector)
        .map(|template| {
            let name = template.select(&name_selector).next().unwrap().inner_html();
            let qfmt = template.select(&qfmt_selector).next().unwrap().inner_html();
            let afmt = template.select(&afmt_selector).next().unwrap().inner_html();
            let bqfmt = template
                .select(&bqfmt_selector)
                .next()
                .unwrap()
                .inner_html();
            let bafmt = template
                .select(&bafmt_selector)
                .next()
                .unwrap()
                .inner_html();

            Template::new(&name)
                .qfmt(&qfmt)
                .afmt(&afmt)
                .bqfmt(&bqfmt)
                .bafmt(&bafmt)
        })
        .collect()
}
