Zaimplementować w asemblerze funkcję, która oblicza wybrany fragment części ułamkowej dwójkowego rozwinięcia liczby π i którą można wywołać z języka C. Należy użyć w tym celu formuły Baileya–Borweina–Plouffe'a. Dla problemu obliczenia początkowych cyfr rozwinięcia π znane są formuły szybciej zbieżne, ale ta ma dwie zalety. Po pierwsze można za jej pomocą obliczać cyfry od pewnego miejsca bez znajomości poprzednich cyfr, co sprawia, że łatwo jest zrównoleglić obliczenia. Po drugie do jej implementacji wystarczy arytmetyka stałopozycyjna, co sprawia, że implementacja może być bardzo szybka.

Implementowana funkcja ma się nazywać pix i ma mieć następującą deklarację w języku C:

void pix(uint32_t *ppi, uint64_t *pidx, uint64_t max);
Parametr ppi jest wskaźnikiem na tablicę, gdzie funkcja umieszcza obliczone wartości. W elemencie o indeksie m tej tablicy mają się znaleźć 32 bity rozwinięcia od bitu numer 32m+1 do bitu numer 32m+32. Bit numer m ma w rozwinięciu wagę 2−m. Innymi słowy w ppi[m] ma się znaleźć wartość [232{232mπ}], gdzie [x] i {x} oznaczają odpowiednio część całkowitą i ułamkową liczby x. Przykładowo początkowe 8 elementów tej tablicy powinno zostać wypełnione wartościami (dla ułatwienia zapisanymi szesnastkowo):

243F6A88
85A308D3
13198A2E
03707344
A4093822
299F31D0
082EFA98
EC4E6C89
Parametr pidx jest wskaźnikiem na indeks elementu w tablicy ppi. Funkcja pix działa w pętli. W każdej iteracji wykonuje atomową operację pobrania wartości tego indeksu i zwiększenia jego wartości o jeden. Przyjmijmy, że pobrana (przed zwiększeniem) wartość wynosi m. Jeśli m jest mniejsze niż wartość parametru max, funkcja oblicza bity rozwinięcia o numerach od 32m+1 do 32m+32 i umieszcza wynik w ppi[m]. Jeśli m jest większe lub równe max funkcja kończy działanie.

Jednocześnie może być uruchomionych wiele instancji funkcji pix, każda w osobnym wątku. Instancje te mają dostęp do wspólnej globalnej zmiennej wskazywanej przez parametr pidx oraz globalnej tablicy ppi i dzielą między siebie pracę, używając tych globalnych zmiennych w wyżej opisany sposób.

Dodatkowo funkcja pix powinna zaraz na początku swojego działania oraz tuż przed zakończeniem wywołać funkcję pixtime, która będzie zaimplementowana w języku C na przykład tak:

void pixtime(uint64_t clock_tick) {
  fprintf(stderr, "%016lX\n", clock_tick);
}
i przekazać jej jako wartość parametru clock_tick liczbę cykli procesora, jaka upłynęła od jego uruchomienia, uzyskaną za pomocą rozkazu rdtsc.

Rozwiązanie ma używać wyłącznie arytmetyki stałopozycyjnej.
