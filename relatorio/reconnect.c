#include <stdio.h>
#include <stdlib.h>

//estrutura de cada nó da lista de adjacencia
typedef struct lista_adj_aux{
	int indice;
	int peso;
	struct lista_adj_aux *prox;
} lista_adj_no, *lista_adj;

//estrutura de cada vertice na representacao de lista de adjacencia
typedef struct vertice_aux{
	lista_adj cabeca;
	int chave;
	int posicao;//posicao no heap
} vertice;

//lista ligada
typedef struct lista_ligada_aux{
	int chave;
	struct lista_ligada_aux *prox;
}lista_ligada_cell, *lista_ligada;

//variaveis globais
int n, m, n_heap, k;
vertice grafo[10000];
int mst[10000][2];
int heap[10000];

//insere uma aresta na lista de adjacencia
void insereLista(int v1, int v2, int peso){
	lista_adj aux = grafo[v1].cabeca -> prox;
	lista_adj novo;
	
	novo = malloc(sizeof(lista_adj_no));
	grafo[v1].cabeca -> prox = novo;
	novo -> prox = aux;
	novo -> indice = v2;
	novo -> peso = peso;
}

//libera lista de adjacencia do vertice v
void liberaLista(int v){
	lista_adj lista = grafo[v].cabeca -> prox;
	lista_adj aux;
	
	while(lista != NULL){
		aux = lista;
		lista = lista -> prox;
		free(aux);
	}
	
	grafo[v].cabeca -> prox = NULL;
}

//inicia as listas de adjacencias com cabecas vazias, e as cores e distancias dos vertices
void iniciaGrafo(){
	int i;
	
	for(i = 0; i < n; i++){
		grafo[i].cabeca = malloc(sizeof(lista_adj_no));
		grafo[i].chave = 9999; //9999 representa infinito
		grafo[i].cabeca -> prox = NULL;
		grafo[i].posicao = i;
	}
}

//converte a arvore mst para um grafo nao direcionado
void iniciaGrafoMst(){
	int i;
	
	for(i = 1; i < n; i++){
		insereLista(i, mst[i][0], mst[i][1]);
		insereLista(mst[i][0], i, mst[i][1]);
	}
}

//remove uma aresta na lista de adjacencia
void removeLista(int v1, int v2){
	lista_adj p, q;
	p = grafo[v1].cabeca;
	q = p -> prox;
	
	while((q != NULL) && (q -> indice != v2)){
		p = q;
		q = q -> prox;
	}
	
	if(q != NULL){
		p -> prox = q -> prox;
		free(q);
	}
}

//funcao auxiliar que imprime uma lista de adjacencia
void imprimeLista(int i){
	lista_adj aux = grafo[i].cabeca -> prox;
	
	printf("VERTICE: %d -> ", i);
	while(aux != NULL){
		printf("%d/%d  ", aux -> indice, aux -> peso);
		aux = aux -> prox;
	}
	printf("\n");
}

//inicia heap com os nóss
void iniciaHeap(){
	int i;
	for(i = 0; i < n_heap; i++)
		heap[i] = i;
}

void trocaHeap(int v1, int v2){
	int aux = heap[v1];
	
	//atualiza as posicoes
	grafo[heap[v1]].posicao = v2;
	grafo[heap[v2]].posicao = v1;
	
	//troca os vertices
	heap[v1] = heap[v2];
	heap[v2] = aux;
}

//Conserta o heap depois da remocao
void heapify(int atual){
	int esq, dir, menor;
	menor = atual;
	esq = 2 * atual + 1;
	dir = 2 * atual + 2;
	
	if((esq < n_heap) && (grafo[heap[esq]].chave < grafo[heap[menor]].chave))
		menor = esq;
	
	if((dir < n_heap) && (grafo[heap[dir]].chave < grafo[heap[menor]].chave))
		menor = dir;
		
	if(menor != atual){
		trocaHeap(menor, atual);
		
		//chama recursivamente pro menor
		heapify(menor);
	}
}

//Extrai vertice de menor chave
int extractMin(){
	int aux;
	if(n_heap != 0){
		aux = heap[0];
		heap[0] = heap[n_heap-1];
		n_heap--;
		grafo[aux].posicao = -1;
		grafo[heap[0]].posicao = 0;
		heapify(0);
	}
	
	return aux; 
}

//Atualiza heap após mudar chave de vertice
void diminuiChave(int v){
	int i = grafo[v].posicao;
	
	while((i > 0) && (grafo[heap[i]].chave < grafo[heap[(i -1) / 2]].chave)){
		trocaHeap(i, (i-1) / 2);
		
		//atualiza para o pai no heap
		i = (i - 1) / 2; 
	}
}

//algoritmo de prim, constroi mst
void prim(){
	lista_adj v;
	int x, y, u;
	
	n_heap = n;
	iniciaHeap();
	grafo[0].chave = 0;
	
	while(n_heap > 0){
		u = extractMin();
		
		v = grafo[u].cabeca -> prox;
		while(v != NULL){
			x = grafo[v -> indice].chave;
			y = v -> peso;
			
			if((grafo[v -> indice].posicao != -1) && (y < x)){
				grafo[v -> indice].chave = y;
				diminuiChave(v -> indice);
				mst[v -> indice][0] = u;
				mst[v -> indice][1] = v -> peso;
			} 
			
			v = v -> prox;
		}
	}
}

//dfs modificado para descobrir o caminho de u a v e a aresta (a, b) de maior custo
int dfs(int u, int v, int *a, int *b, int *custo){
	lista_adj adjacentes = grafo[u].cabeca -> prox;
	int flag = 0;
	grafo[u].chave = 1;
	
	if(u != v){
		while((adjacentes != NULL) && (!flag)){
			if(grafo[adjacentes -> indice].chave == 0){
				flag = dfs(adjacentes -> indice, v, a, b, custo);
				
				if(flag && (*custo < (adjacentes -> peso))){
					(*custo) = (adjacentes -> peso);
					(*a) = u;
					(*b) = adjacentes -> indice;
				}
			}
			
			adjacentes = adjacentes -> prox;
		}
		
		grafo[u].chave = 2;
		
		return flag;
	}
	
	else 
		return 1;
}

int main(){
	int i, j, v1, v2, peso;
	int c1 = 0;
	
	scanf("%d", &n);
	m = n -1;
	
	iniciaGrafo();
	
	//Le o grafo
	for(i = 0; i < m; i++){
		scanf("%d %d %d", &v1, &v2, &peso);
		insereLista(v1, v2, peso);
		insereLista(v2, v1, peso);
	}
	
	prim();
	
	//calcula custo da mst e libera a lista ligada do vertice i
	for(i = 0; i < n; i++){
		c1 += mst[i][1];
		liberaLista(i);
	}
	iniciaGrafoMst();

	//aqui comeca a ler as novas arestas a serem inseridas
	scanf("%d", &k);
	
	int w, a, b, c2;
	c2 = c1;
	
	for(i = 0; i < k; i++){
		scanf("%d %d %d", &v1, &v2, &peso);
		
		//inicializa
		for(j = 0; j < n; j++)
			grafo[j].chave = 0;
		w = -9999;
		
		//busca caminho de v1 a v2
		dfs(v1, v2, &a, &b, &w);
		
		//atualiza a mst se peso < w da nova aresta
		if(peso < w){
			removeLista(a, b);
			removeLista(b, a);
			insereLista(v1, v2, peso);
			insereLista(v2, v1, peso);
			
			//novo custo
			c2 -= (w - peso);
		}
	}
	
	printf("%d %d\n", c1, c2);
	return 0;
}
