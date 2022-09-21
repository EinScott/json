# Json for Beef

Read and write standard **JSON** in [BeefLang](https://github.com/beefytech/Beef). Focused on speed and usability.

## Reading
The whole structure is contained within ``JsonTree``. When the ``ReadJson`` call fails, ``tree`` is probably in an incomplete state, and might be partially invalid (e.g. ``.Object(let o)``'s ``o`` might be ``null``) but will always be correctly deletable. ``.Err(let err)`` will contain an error code, as well as column and line info.

The life time of all ``Dictionary``, ``List`` and ``String`` objects within the tree is **irreversably** tied to it.

```bf
let tree = scope JsonTree();
switch (Json.ReadJson(jsonString, tree)
{
case .Err(let err):
    Debug.WriteLine(err);
    return .Err;
case .Ok:
}

// Use tree...
// - handle unexpected structures:

if (tree.root case .Object(let objData))
{
    if (rootObj.TryGetValue("answer", let truthBool)
        && truthBool case .Bool(let bool))
    {
        Debug.WriteLine(bool ? "Yup" : "Nup");
    }
    else return .Err;

    // ...
}
else return .Err;

// - just crash on unexpected structures:

let truthBool = tree.root.AsObject()["answer"].AsBool();
Debug.WriteLine(bool ? "Yeah" : "Nahh");
```

### Options

- ``Json.readerMaxDepth`` Maximum allowed object/array depth, 256 by default
- ``Json.readerDuplicateKeyBehaviour`` Behaviour when encountering a duplicate key in an object. Can be ``.Override`` (default), or ``.Error``

## Writing
``JsonTree`` can be modified and converted back to JSON. ``Dictionary``, ``List`` and ``String`` objects that are used in the tree **may** be allocated, and thus be automatically deleted, with it (handy when storing or returning created trees). But this is not strictly required, meaning for example strings that are in scope at the time of writing the tree, as well as ``const`` strings can still be used as well.

```bf
let tree = scope JsonTree();

// Make object data, allocation life time is tied to tree
let rootObj = tree.MakeOwnedObject();
tree.root = .Object(rootObj); // Assign to structure

// Usual dicationary adding... for example:
rootObj["nothing here"] = .Null;

let treeBoundStr = tree.MakeOwnedString("keyValueThingBothYeaUseful");
rootObj[treeBoundStr] = .String(treeBoundStr);

let array = tree.MakeOwnedArray(8); // Already know required capacity!
rootObj["someArrayThing"] = .Array(array);
for (let i < 8)
{
    // Usual List adding...
    array.Add(.Number(Math.Pow(i, i) / 10));
}

// WriteJson just returns void, so we can just:
let jsonString = Json.WriteJson(tree, .. scope .(128));
```
