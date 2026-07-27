#include <iostream>
#include <string>
#include <vector>
#include <algorithm>
#include <random>
#include <ctime>

int main() {
    std::vector<std::string> initial_candidates = {
        "しりとり", "すいか", "かめら", "らいおん", 
        "さくら", "らくだ", "だんご", "ごりら"
    };

    std::mt19937 rng(static_cast<unsigned int>(std::time(nullptr)));

    auto get_random_start_word = [&]() {
        std::uniform_int_distribution<size_t> dist(0, initial_candidates.size() - 1);
        return initial_candidates[dist(rng)];
    };

    std::vector<std::string> history;
    
    std::string previous_word = get_random_start_word();
    history.push_back(previous_word);

    std::cout << "--- しりとりゲーム (C++) ---" << std::endl;

    std::string next_word;

    while (true) {
        std::string target_char = previous_word.substr(previous_word.length() - 3, 3);
        
        std::cout << "\n----------------------------------------" << std::endl;
        
        if (history.size() == 1) {
            std::cout << "【最初の単語】: " << previous_word << " (次は『" << target_char << "』から)" << std::endl;
        } else {
            std::cout << "【前回の単語】: " << previous_word << " (次は『" << target_char << "』から)" << std::endl;
        }

        std::cout << "次の単語を入力してください > ";
        
        if (!(std::cin >> next_word)) {
            break;
        }

        if (next_word == "reset") {
            history.clear();
            previous_word = get_random_start_word();
            history.push_back(previous_word);
            std::cout << "\n--- リセットしました！ ---" << std::endl;
            continue;
        }

        if (next_word.length() < 3) {
            std::cout << "エラー: ひらがなで入力してください！" << std::endl;
            continue;
        }

        std::string prev_last = previous_word.substr(previous_word.length() - 3, 3);
        std::string next_first = next_word.substr(0, 3);

        if (prev_last != next_first) {
            std::cout << "エラー: 『" << prev_last << "』から始まる単語を入力してください！" << std::endl;
            continue;
        }

        std::string next_last = next_word.substr(next_word.length() - 3, 3);
        if (next_last == "ん") {
            std::cout << "\n『ん』で終わりました。あなたの負けです！" << std::endl;
            break;
        }

        auto it = std::find(history.begin(), history.end(), next_word);
        if (it != history.end()) {
            std::cout << "\n「" << next_word << "」は過去に出た単語です。あなたの負けです！" << std::endl;
            break;
        }

        history.push_back(next_word);
        previous_word = next_word;
    }

    return 0;
}