(* OASIS_START *)
(* OASIS_STOP *)
# 3 "myocamlbuild.ml"

(* Temporary hacks *)
let js_hacks = function
  | After_rules ->
    rule "Generate a cmxs from a cmxa"
      ~dep:"%.cmxa"
      ~prod:"%.cmxs"
      ~insert:`top
      (fun env _ ->
         Cmd (S [ !Options.ocamlopt
                ; A "-shared"
                ; A "-linkall"
                ; A "-I"; A (Pathname.dirname (env "%"))
                ; A (env "%.cmxa")
                ; A "-o"
                ; A (env "%.cmxs")
            ]));

    (* Pass -predicates to ocamldep *)
    pflag ["ocaml"; "ocamldep"] "predicate" (fun s -> S [A "-predicates"; A s])
  | _ -> ()

let dispatch = function
  | After_rules ->
    let gen_and_mv generator files =
      let in_src = List.map (fun fn -> "src" / fn) files in
      rule ("gen " ^ String.concat " " files)
        ~dep:generator
        ~prods:in_src
        (fun _ _ ->
          Seq (Cmd (S [ P generator
                      ; A "-I"
                      ; A "+compiler-libs"
                      ; A "Parsetree"
                      ])
               :: List.map2 mv files in_src))
    in

    gen_and_mv "src/gen/gen.byte"
      [ "ast_traverse_map.ml"
      ; "ast_traverse_map.mli"
      ; "ast_traverse_iter.ml"
      ; "ast_traverse_iter.mli"
      ; "ast_traverse_fold.ml"
      ; "ast_traverse_fold.mli"
      ; "ast_traverse_fold_map.ml"
      ; "ast_traverse_fold_map.mli"
      ; "ast_traverse_map_with_context.ml"
      ; "ast_traverse_map_with_context.mli"
      ];

    gen_and_mv "src/gen/gen_ast_pattern.byte" ["ast_pattern_generated.ml"];
    gen_and_mv "src/gen/gen_ast_builder.byte" ["ast_builder_generated.ml"];
  | _ ->
    ()

let () =
  Ocamlbuild_plugin.dispatch (fun hook ->
    js_hacks hook;
    dispatch hook;
    dispatch_default hook)

