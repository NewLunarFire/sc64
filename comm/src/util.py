def find_first(my_list, predicate):
    # The generator expression produces values that match the condition
    generator = (x for x in my_list if predicate(x))

    # The next() function returns the first value from the generator
    first_match = next(generator, None) # The 'None' is a default value if no match is found

    return first_match