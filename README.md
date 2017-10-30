### cm

Interactive git change management

Tool was created to help simplify my workflow. Type `cm` and tool will iterate over all the changes prompting you to input what you want to do with them.

Example:

```batch

C:\workspace\bat\cm>cm
diff --git a/src/cpp/MyFile.h b/src/cpp/MyFile.h
index 8675308..8675309 100644
--- a/src/cpp/MyFile.h
+++ b/src/cpp/MyFile.h
@@ -38,7 +38,7 @@ namespace My { namespace Space {
        {
        private:
                std::unique_ptr<Something> _ptr;
-               array<OtherThing^>^ _listOfThings;
+               My::Space::array<OtherThing^>^ _listOfThings;

        public:
                ThisClass() :
Would you like to [A]ccept Change(s), [S]kip the file(s), [M]odify the file(s), [R]evert the file(s), [Q]uit?

```
