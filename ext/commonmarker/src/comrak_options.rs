use comrak::ComrakOptions;

use magnus::{class, r_hash::ForEach, Error, RHash, Symbol, Value};

fn iterate_parse_options(comrak_options: &mut ComrakOptions, options_hash: RHash) {
    options_hash.foreach(|key: Symbol, value: Value| {
        if key.name().unwrap() == "smart" {
            comrak_options.parse.smart = value.try_convert::<bool>()?;
        }
        if key.name().unwrap() == "default_info_string" {
            comrak_options.parse.default_info_string = Some(value.try_convert::<String>().unwrap());
        }
        Ok(ForEach::Continue)
    });
}

fn iterate_render_options(comrak_options: &mut ComrakOptions, options_hash: RHash) {
    options_hash.foreach(|key: Symbol, value: Value| {
        if key.name().unwrap() == "hardbreaks" {
            comrak_options.render.hardbreaks = value.try_convert::<bool>()?;
        }

        if key.name().unwrap() == "github_pre_lang" {
            comrak_options.render.github_pre_lang = value.try_convert::<bool>()?;
        }

        if key.name().unwrap() == "width" {
            comrak_options.render.width = value.try_convert::<usize>()?;
        }

        if key.name().unwrap() == "unsafe_" {
            comrak_options.render.unsafe_ = value.try_convert::<bool>()?;
        }

        if key.name().unwrap() == "escape" {
            comrak_options.render.escape = value.try_convert::<bool>()?;
        }

        Ok(ForEach::Continue)
    });
}

fn iterate_extension_options(comrak_options: &mut ComrakOptions, options_hash: RHash) {
    options_hash.foreach(|key: Symbol, value: Value| {
        if key.name().unwrap() == "strikethrough" {
            comrak_options.extension.strikethrough = value.try_convert::<bool>()?;
        }

        if key.name().unwrap() == "tagfilter" {
            comrak_options.extension.tagfilter = value.try_convert::<bool>()?;
        }

        if key.name().unwrap() == "table" {
            comrak_options.extension.table = value.try_convert::<bool>()?;
        }

        if key.name().unwrap() == "autolink" {
            comrak_options.extension.autolink = value.try_convert::<bool>()?;
        }

        if key.name().unwrap() == "tasklist" {
            comrak_options.extension.tasklist = value.try_convert::<bool>()?;
        }

        if key.name().unwrap() == "superscript" {
            comrak_options.extension.superscript = value.try_convert::<bool>()?;
        }

        if key.name().unwrap() == "header_ids" {
            comrak_options.extension.header_ids = Some(value.try_convert::<String>().unwrap());
        }

        if key.name().unwrap() == "footnotes" {
            comrak_options.extension.footnotes = value.try_convert::<bool>()?;
        }

        if key.name().unwrap() == "description_lists" {
            comrak_options.extension.description_lists = value.try_convert::<bool>()?;
        }

        if key.name().unwrap() == "front_matter_delimiter" {
            comrak_options.extension.front_matter_delimiter =
                Some(value.try_convert::<String>().unwrap());
        }

        Ok(ForEach::Continue)
    });
}

pub fn iterate_options_hash(
    comrak_options: &mut ComrakOptions,
    key: Symbol,
    value: RHash,
) -> Result<ForEach, Error> {
    assert!(value.is_kind_of(class::hash()));

    if key.name().unwrap() == "parse" {
        iterate_parse_options(comrak_options, value);
    }
    if key.name().unwrap() == "render" {
        iterate_render_options(comrak_options, value);
    }
    if key.name().unwrap() == "extension" {
        iterate_extension_options(comrak_options, value);
    }
    Ok(ForEach::Continue)
}
