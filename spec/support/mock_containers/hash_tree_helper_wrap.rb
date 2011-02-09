# An empty class that imports HashTreeHelper, for use in specs.
#
# Higher-level specs should use BareHashTree, which imports HashTreeHelper on
# top of an unsecured in-memory tree.
class HashTreeHelperWrap
  include SpStore::Merkle::HashTreeHelper
end
