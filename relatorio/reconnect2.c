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
	int cor;
} vertice;

//lista ligada
typedef struct lista_ligada_aux{
	int chave;
	struct lista_ligada_aux *prox;
}lista_ligada_cell, *lista_ligada;

//variaveis globais
int n, m, k;
vertice grafo[10000];

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

//inicia as listas de adjacencias com cabecas vazias, e as cores e distancias dos vertices
void iniciaGrafo(){
	int i;
	
	for(i = 0; i < n; i++){
		grafo[i].cabeca = malloc(sizeof(lista_adj_no));
		grafo[i].cabeca -> prox = NULL;
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

//dfs modificado para descobrir o caminho de u a v e a aresta (a, b) de maior custo
int dfs(int u, int v, int *a, int *b, int *custo){
	lista_adj adjacentes = grafo[u].cabeca -> prox;
	int flag = 0;
	grafo[u].cor = 1;
	
	if(u != v){
		while((adjacentes != NULL) && (!flag)){
			if(grafo[adjacentes -> indice].cor== 0){
				flag = dfs(adjacentes -> indice, v, a, b, custo);
				
				if(flag && (*custo < (adjacentes -> peso))){
					(*custo) = (adjacentes -> peso);
					(*a) = u;
					(*b) = adjacentes -> indice;
				}
			}
			
			adjacentes = adjacentes -> prox;
		}
		
		grafo[u].cor = 2;
		
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
		c1 += peso;
	}

	//aqui comeca a ler as novas arestas a serem inseridas
	scanf("%d", &k);
	
	int w, a, b, c2;
	c2 = c1;
	
	for(i = 0; i < k; i++){
		scanf("%d %d %d", &v1, &v2, &peso);
		
		//inicializa
		for(j = 0; j < n; j++)
			grafo[j].cor = 0;
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
