
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS App Mesh
## version: 2019-01-25
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p>AWS App Mesh is a service mesh based on the Envoy proxy that makes it easy to monitor and
##          control microservices. App Mesh standardizes how your microservices communicate, giving you
##          end-to-end visibility and helping to ensure high availability for your applications.</p>
##          <p>App Mesh gives you consistent visibility and network traffic controls for every
##          microservice in an application. You can use App Mesh with AWS Fargate, Amazon ECS, Amazon EKS,
##          Kubernetes on AWS, and Amazon EC2.</p>
##          <note>
##             <p>App Mesh supports microservice applications that use service discovery naming for their
##             components. For more information about service discovery on Amazon ECS, see <a href="http://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-discovery.html">Service Discovery</a> in the
##                <i>Amazon Elastic Container Service Developer Guide</i>. Kubernetes <code>kube-dns</code> and
##                <code>coredns</code> are supported. For more information, see <a href="https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/">DNS
##                for Services and Pods</a> in the Kubernetes documentation.</p>
##          </note>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/appmesh/
type
  Scheme {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (query: JsonNode = nil; body: JsonNode = nil;
                          header: JsonNode = nil; path: JsonNode = nil;
                          formData: JsonNode = nil): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    url*: proc (protocol: Scheme; host: string; base: string; route: string;
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_592364 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_592364](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_592364): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low ..
      Scheme.high:
    if scheme notin t.schemes:
      continue
    if scheme in [Scheme.Https, Scheme.Wss]:
      when defined(ssl):
        return some(scheme)
      else:
        continue
    return some(scheme)

proc validateParameter(js: JsonNode; kind: JsonNodeKind; required: bool;
                      default: JsonNode = nil): JsonNode =
  ## ensure an input is of the correct json type and yield
  ## a suitable default value when appropriate
  if js ==
      nil:
    if default != nil:
      return validateParameter(default, kind, required = required)
  result = js
  if result ==
      nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind ==
        kind, $kind & " expected; received " &
        $js.kind

type
  KeyVal {.used.} = tuple[key: string, val: string]
  PathTokenKind = enum
    ConstantSegment, VariableSegment
  PathToken = tuple[kind: PathTokenKind, value: string]
proc queryString(query: JsonNode): string {.used.} =
  var qs: seq[KeyVal]
  if query == nil:
    return ""
  for k, v in query.pairs:
    qs.add (key: k, val: v.getStr)
  result = encodeQuery(qs)

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.used.} =
  ## reconstitute a path with constants and variable values taken from json
  var head: string
  if segments.len == 0:
    return some("")
  head = segments[0].value
  case segments[0].kind
  of ConstantSegment:
    discard
  of VariableSegment:
    if head notin input:
      return
    let js = input[head]
    case js.kind
    of JInt, JFloat, JNull, JBool:
      head = $js
    of JString:
      head = js.getStr
    else:
      return
  var remainder = input.hydratePath(segments[1 ..^ 1])
  if remainder.isNone:
    return
  result = some(head & remainder.get)

const
  awsServers = {Scheme.Http: {"ap-northeast-1": "appmesh.ap-northeast-1.amazonaws.com", "ap-southeast-1": "appmesh.ap-southeast-1.amazonaws.com",
                           "us-west-2": "appmesh.us-west-2.amazonaws.com",
                           "eu-west-2": "appmesh.eu-west-2.amazonaws.com", "ap-northeast-3": "appmesh.ap-northeast-3.amazonaws.com", "eu-central-1": "appmesh.eu-central-1.amazonaws.com",
                           "us-east-2": "appmesh.us-east-2.amazonaws.com",
                           "us-east-1": "appmesh.us-east-1.amazonaws.com", "cn-northwest-1": "appmesh.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "appmesh.ap-south-1.amazonaws.com",
                           "eu-north-1": "appmesh.eu-north-1.amazonaws.com", "ap-northeast-2": "appmesh.ap-northeast-2.amazonaws.com",
                           "us-west-1": "appmesh.us-west-1.amazonaws.com", "us-gov-east-1": "appmesh.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "appmesh.eu-west-3.amazonaws.com",
                           "cn-north-1": "appmesh.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "appmesh.sa-east-1.amazonaws.com",
                           "eu-west-1": "appmesh.eu-west-1.amazonaws.com", "us-gov-west-1": "appmesh.us-gov-west-1.amazonaws.com", "ap-southeast-2": "appmesh.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "appmesh.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "appmesh.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "appmesh.ap-southeast-1.amazonaws.com",
      "us-west-2": "appmesh.us-west-2.amazonaws.com",
      "eu-west-2": "appmesh.eu-west-2.amazonaws.com",
      "ap-northeast-3": "appmesh.ap-northeast-3.amazonaws.com",
      "eu-central-1": "appmesh.eu-central-1.amazonaws.com",
      "us-east-2": "appmesh.us-east-2.amazonaws.com",
      "us-east-1": "appmesh.us-east-1.amazonaws.com",
      "cn-northwest-1": "appmesh.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "appmesh.ap-south-1.amazonaws.com",
      "eu-north-1": "appmesh.eu-north-1.amazonaws.com",
      "ap-northeast-2": "appmesh.ap-northeast-2.amazonaws.com",
      "us-west-1": "appmesh.us-west-1.amazonaws.com",
      "us-gov-east-1": "appmesh.us-gov-east-1.amazonaws.com",
      "eu-west-3": "appmesh.eu-west-3.amazonaws.com",
      "cn-north-1": "appmesh.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "appmesh.sa-east-1.amazonaws.com",
      "eu-west-1": "appmesh.eu-west-1.amazonaws.com",
      "us-gov-west-1": "appmesh.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "appmesh.ap-southeast-2.amazonaws.com",
      "ca-central-1": "appmesh.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "appmesh"
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateMesh_592960 = ref object of OpenApiRestCall_592364
proc url_CreateMesh_592962(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateMesh_592961(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a service mesh. A service mesh is a logical boundary for network traffic between
  ##          the services that reside within it.</p>
  ##          <p>After you create your service mesh, you can create virtual services, virtual nodes,
  ##          virtual routers, and routes to distribute traffic between the applications in your
  ##          mesh.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592963 = header.getOrDefault("X-Amz-Signature")
  valid_592963 = validateParameter(valid_592963, JString, required = false,
                                 default = nil)
  if valid_592963 != nil:
    section.add "X-Amz-Signature", valid_592963
  var valid_592964 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592964 = validateParameter(valid_592964, JString, required = false,
                                 default = nil)
  if valid_592964 != nil:
    section.add "X-Amz-Content-Sha256", valid_592964
  var valid_592965 = header.getOrDefault("X-Amz-Date")
  valid_592965 = validateParameter(valid_592965, JString, required = false,
                                 default = nil)
  if valid_592965 != nil:
    section.add "X-Amz-Date", valid_592965
  var valid_592966 = header.getOrDefault("X-Amz-Credential")
  valid_592966 = validateParameter(valid_592966, JString, required = false,
                                 default = nil)
  if valid_592966 != nil:
    section.add "X-Amz-Credential", valid_592966
  var valid_592967 = header.getOrDefault("X-Amz-Security-Token")
  valid_592967 = validateParameter(valid_592967, JString, required = false,
                                 default = nil)
  if valid_592967 != nil:
    section.add "X-Amz-Security-Token", valid_592967
  var valid_592968 = header.getOrDefault("X-Amz-Algorithm")
  valid_592968 = validateParameter(valid_592968, JString, required = false,
                                 default = nil)
  if valid_592968 != nil:
    section.add "X-Amz-Algorithm", valid_592968
  var valid_592969 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592969 = validateParameter(valid_592969, JString, required = false,
                                 default = nil)
  if valid_592969 != nil:
    section.add "X-Amz-SignedHeaders", valid_592969
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592971: Call_CreateMesh_592960; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a service mesh. A service mesh is a logical boundary for network traffic between
  ##          the services that reside within it.</p>
  ##          <p>After you create your service mesh, you can create virtual services, virtual nodes,
  ##          virtual routers, and routes to distribute traffic between the applications in your
  ##          mesh.</p>
  ## 
  let valid = call_592971.validator(path, query, header, formData, body)
  let scheme = call_592971.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592971.url(scheme.get, call_592971.host, call_592971.base,
                         call_592971.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592971, url, valid)

proc call*(call_592972: Call_CreateMesh_592960; body: JsonNode): Recallable =
  ## createMesh
  ## <p>Creates a service mesh. A service mesh is a logical boundary for network traffic between
  ##          the services that reside within it.</p>
  ##          <p>After you create your service mesh, you can create virtual services, virtual nodes,
  ##          virtual routers, and routes to distribute traffic between the applications in your
  ##          mesh.</p>
  ##   body: JObject (required)
  var body_592973 = newJObject()
  if body != nil:
    body_592973 = body
  result = call_592972.call(nil, nil, nil, nil, body_592973)

var createMesh* = Call_CreateMesh_592960(name: "createMesh",
                                      meth: HttpMethod.HttpPut,
                                      host: "appmesh.amazonaws.com",
                                      route: "/v20190125/meshes",
                                      validator: validate_CreateMesh_592961,
                                      base: "/", url: url_CreateMesh_592962,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMeshes_592703 = ref object of OpenApiRestCall_592364
proc url_ListMeshes_592705(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListMeshes_592704(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of existing service meshes.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : <p>The <code>nextToken</code> value returned from a previous paginated
  ##             <code>ListMeshes</code> request where <code>limit</code> was used and the results
  ##          exceeded the value of that parameter. Pagination continues from the end of the previous
  ##          results that returned the <code>nextToken</code> value.</p> 
  ##          <note>
  ##             <p>This token should be treated as an opaque identifier that is used only to
  ##                 retrieve the next items in a list and not for other programmatic purposes.</p>
  ##         </note>
  ##   limit: JInt
  ##        : The maximum number of results returned by <code>ListMeshes</code> in paginated output.
  ##          When you use this parameter, <code>ListMeshes</code> returns only <code>limit</code>
  ##          results in a single page along with a <code>nextToken</code> response element. You can see
  ##          the remaining results of the initial request by sending another <code>ListMeshes</code>
  ##          request with the returned <code>nextToken</code> value. This value can be between
  ##          1 and 100. If you don't use this parameter,
  ##             <code>ListMeshes</code> returns up to 100 results and a
  ##             <code>nextToken</code> value if applicable.
  section = newJObject()
  var valid_592817 = query.getOrDefault("nextToken")
  valid_592817 = validateParameter(valid_592817, JString, required = false,
                                 default = nil)
  if valid_592817 != nil:
    section.add "nextToken", valid_592817
  var valid_592818 = query.getOrDefault("limit")
  valid_592818 = validateParameter(valid_592818, JInt, required = false, default = nil)
  if valid_592818 != nil:
    section.add "limit", valid_592818
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592819 = header.getOrDefault("X-Amz-Signature")
  valid_592819 = validateParameter(valid_592819, JString, required = false,
                                 default = nil)
  if valid_592819 != nil:
    section.add "X-Amz-Signature", valid_592819
  var valid_592820 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592820 = validateParameter(valid_592820, JString, required = false,
                                 default = nil)
  if valid_592820 != nil:
    section.add "X-Amz-Content-Sha256", valid_592820
  var valid_592821 = header.getOrDefault("X-Amz-Date")
  valid_592821 = validateParameter(valid_592821, JString, required = false,
                                 default = nil)
  if valid_592821 != nil:
    section.add "X-Amz-Date", valid_592821
  var valid_592822 = header.getOrDefault("X-Amz-Credential")
  valid_592822 = validateParameter(valid_592822, JString, required = false,
                                 default = nil)
  if valid_592822 != nil:
    section.add "X-Amz-Credential", valid_592822
  var valid_592823 = header.getOrDefault("X-Amz-Security-Token")
  valid_592823 = validateParameter(valid_592823, JString, required = false,
                                 default = nil)
  if valid_592823 != nil:
    section.add "X-Amz-Security-Token", valid_592823
  var valid_592824 = header.getOrDefault("X-Amz-Algorithm")
  valid_592824 = validateParameter(valid_592824, JString, required = false,
                                 default = nil)
  if valid_592824 != nil:
    section.add "X-Amz-Algorithm", valid_592824
  var valid_592825 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592825 = validateParameter(valid_592825, JString, required = false,
                                 default = nil)
  if valid_592825 != nil:
    section.add "X-Amz-SignedHeaders", valid_592825
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592848: Call_ListMeshes_592703; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of existing service meshes.
  ## 
  let valid = call_592848.validator(path, query, header, formData, body)
  let scheme = call_592848.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592848.url(scheme.get, call_592848.host, call_592848.base,
                         call_592848.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592848, url, valid)

proc call*(call_592919: Call_ListMeshes_592703; nextToken: string = ""; limit: int = 0): Recallable =
  ## listMeshes
  ## Returns a list of existing service meshes.
  ##   nextToken: string
  ##            : <p>The <code>nextToken</code> value returned from a previous paginated
  ##             <code>ListMeshes</code> request where <code>limit</code> was used and the results
  ##          exceeded the value of that parameter. Pagination continues from the end of the previous
  ##          results that returned the <code>nextToken</code> value.</p> 
  ##          <note>
  ##             <p>This token should be treated as an opaque identifier that is used only to
  ##                 retrieve the next items in a list and not for other programmatic purposes.</p>
  ##         </note>
  ##   limit: int
  ##        : The maximum number of results returned by <code>ListMeshes</code> in paginated output.
  ##          When you use this parameter, <code>ListMeshes</code> returns only <code>limit</code>
  ##          results in a single page along with a <code>nextToken</code> response element. You can see
  ##          the remaining results of the initial request by sending another <code>ListMeshes</code>
  ##          request with the returned <code>nextToken</code> value. This value can be between
  ##          1 and 100. If you don't use this parameter,
  ##             <code>ListMeshes</code> returns up to 100 results and a
  ##             <code>nextToken</code> value if applicable.
  var query_592920 = newJObject()
  add(query_592920, "nextToken", newJString(nextToken))
  add(query_592920, "limit", newJInt(limit))
  result = call_592919.call(nil, query_592920, nil, nil, nil)

var listMeshes* = Call_ListMeshes_592703(name: "listMeshes",
                                      meth: HttpMethod.HttpGet,
                                      host: "appmesh.amazonaws.com",
                                      route: "/v20190125/meshes",
                                      validator: validate_ListMeshes_592704,
                                      base: "/", url: url_ListMeshes_592705,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRoute_593006 = ref object of OpenApiRestCall_592364
proc url_CreateRoute_593008(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  assert "virtualRouterName" in path,
        "`virtualRouterName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualRouter/"),
               (kind: VariableSegment, value: "virtualRouterName"),
               (kind: ConstantSegment, value: "/routes")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_CreateRoute_593007(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a route that is associated with a virtual router.</p>
  ##          <p>You can use the <code>prefix</code> parameter in your route specification for path-based
  ##          routing of requests. For example, if your virtual service name is
  ##             <code>my-service.local</code> and you want the route to match requests to
  ##             <code>my-service.local/metrics</code>, your prefix should be
  ##          <code>/metrics</code>.</p>
  ##          <p>If your route matches a request, you can distribute traffic to one or more target
  ##          virtual nodes with relative weighting.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh to create the route in.
  ##   virtualRouterName: JString (required)
  ##                    : The name of the virtual router in which to create the route.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_593009 = path.getOrDefault("meshName")
  valid_593009 = validateParameter(valid_593009, JString, required = true,
                                 default = nil)
  if valid_593009 != nil:
    section.add "meshName", valid_593009
  var valid_593010 = path.getOrDefault("virtualRouterName")
  valid_593010 = validateParameter(valid_593010, JString, required = true,
                                 default = nil)
  if valid_593010 != nil:
    section.add "virtualRouterName", valid_593010
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593011 = header.getOrDefault("X-Amz-Signature")
  valid_593011 = validateParameter(valid_593011, JString, required = false,
                                 default = nil)
  if valid_593011 != nil:
    section.add "X-Amz-Signature", valid_593011
  var valid_593012 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593012 = validateParameter(valid_593012, JString, required = false,
                                 default = nil)
  if valid_593012 != nil:
    section.add "X-Amz-Content-Sha256", valid_593012
  var valid_593013 = header.getOrDefault("X-Amz-Date")
  valid_593013 = validateParameter(valid_593013, JString, required = false,
                                 default = nil)
  if valid_593013 != nil:
    section.add "X-Amz-Date", valid_593013
  var valid_593014 = header.getOrDefault("X-Amz-Credential")
  valid_593014 = validateParameter(valid_593014, JString, required = false,
                                 default = nil)
  if valid_593014 != nil:
    section.add "X-Amz-Credential", valid_593014
  var valid_593015 = header.getOrDefault("X-Amz-Security-Token")
  valid_593015 = validateParameter(valid_593015, JString, required = false,
                                 default = nil)
  if valid_593015 != nil:
    section.add "X-Amz-Security-Token", valid_593015
  var valid_593016 = header.getOrDefault("X-Amz-Algorithm")
  valid_593016 = validateParameter(valid_593016, JString, required = false,
                                 default = nil)
  if valid_593016 != nil:
    section.add "X-Amz-Algorithm", valid_593016
  var valid_593017 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593017 = validateParameter(valid_593017, JString, required = false,
                                 default = nil)
  if valid_593017 != nil:
    section.add "X-Amz-SignedHeaders", valid_593017
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593019: Call_CreateRoute_593006; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a route that is associated with a virtual router.</p>
  ##          <p>You can use the <code>prefix</code> parameter in your route specification for path-based
  ##          routing of requests. For example, if your virtual service name is
  ##             <code>my-service.local</code> and you want the route to match requests to
  ##             <code>my-service.local/metrics</code>, your prefix should be
  ##          <code>/metrics</code>.</p>
  ##          <p>If your route matches a request, you can distribute traffic to one or more target
  ##          virtual nodes with relative weighting.</p>
  ## 
  let valid = call_593019.validator(path, query, header, formData, body)
  let scheme = call_593019.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593019.url(scheme.get, call_593019.host, call_593019.base,
                         call_593019.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593019, url, valid)

proc call*(call_593020: Call_CreateRoute_593006; meshName: string; body: JsonNode;
          virtualRouterName: string): Recallable =
  ## createRoute
  ## <p>Creates a route that is associated with a virtual router.</p>
  ##          <p>You can use the <code>prefix</code> parameter in your route specification for path-based
  ##          routing of requests. For example, if your virtual service name is
  ##             <code>my-service.local</code> and you want the route to match requests to
  ##             <code>my-service.local/metrics</code>, your prefix should be
  ##          <code>/metrics</code>.</p>
  ##          <p>If your route matches a request, you can distribute traffic to one or more target
  ##          virtual nodes with relative weighting.</p>
  ##   meshName: string (required)
  ##           : The name of the service mesh to create the route in.
  ##   body: JObject (required)
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router in which to create the route.
  var path_593021 = newJObject()
  var body_593022 = newJObject()
  add(path_593021, "meshName", newJString(meshName))
  if body != nil:
    body_593022 = body
  add(path_593021, "virtualRouterName", newJString(virtualRouterName))
  result = call_593020.call(path_593021, nil, nil, nil, body_593022)

var createRoute* = Call_CreateRoute_593006(name: "createRoute",
                                        meth: HttpMethod.HttpPut,
                                        host: "appmesh.amazonaws.com", route: "/v20190125/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes",
                                        validator: validate_CreateRoute_593007,
                                        base: "/", url: url_CreateRoute_593008,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRoutes_592974 = ref object of OpenApiRestCall_592364
proc url_ListRoutes_592976(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  assert "virtualRouterName" in path,
        "`virtualRouterName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualRouter/"),
               (kind: VariableSegment, value: "virtualRouterName"),
               (kind: ConstantSegment, value: "/routes")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_ListRoutes_592975(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of existing routes in a service mesh.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh to list routes in.
  ##   virtualRouterName: JString (required)
  ##                    : The name of the virtual router to list routes in.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_592991 = path.getOrDefault("meshName")
  valid_592991 = validateParameter(valid_592991, JString, required = true,
                                 default = nil)
  if valid_592991 != nil:
    section.add "meshName", valid_592991
  var valid_592992 = path.getOrDefault("virtualRouterName")
  valid_592992 = validateParameter(valid_592992, JString, required = true,
                                 default = nil)
  if valid_592992 != nil:
    section.add "virtualRouterName", valid_592992
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The <code>nextToken</code> value returned from a previous paginated
  ##             <code>ListRoutes</code> request where <code>limit</code> was used and the results
  ##          exceeded the value of that parameter. Pagination continues from the end of the previous
  ##          results that returned the <code>nextToken</code> value.
  ##   limit: JInt
  ##        : The maximum number of results returned by <code>ListRoutes</code> in paginated output.
  ##          When you use this parameter, <code>ListRoutes</code> returns only <code>limit</code>
  ##          results in a single page along with a <code>nextToken</code> response element. You can see
  ##          the remaining results of the initial request by sending another <code>ListRoutes</code>
  ##          request with the returned <code>nextToken</code> value. This value can be between
  ##          1 and 100. If you don't use this parameter,
  ##             <code>ListRoutes</code> returns up to 100 results and a
  ##             <code>nextToken</code> value if applicable.
  section = newJObject()
  var valid_592993 = query.getOrDefault("nextToken")
  valid_592993 = validateParameter(valid_592993, JString, required = false,
                                 default = nil)
  if valid_592993 != nil:
    section.add "nextToken", valid_592993
  var valid_592994 = query.getOrDefault("limit")
  valid_592994 = validateParameter(valid_592994, JInt, required = false, default = nil)
  if valid_592994 != nil:
    section.add "limit", valid_592994
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592995 = header.getOrDefault("X-Amz-Signature")
  valid_592995 = validateParameter(valid_592995, JString, required = false,
                                 default = nil)
  if valid_592995 != nil:
    section.add "X-Amz-Signature", valid_592995
  var valid_592996 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592996 = validateParameter(valid_592996, JString, required = false,
                                 default = nil)
  if valid_592996 != nil:
    section.add "X-Amz-Content-Sha256", valid_592996
  var valid_592997 = header.getOrDefault("X-Amz-Date")
  valid_592997 = validateParameter(valid_592997, JString, required = false,
                                 default = nil)
  if valid_592997 != nil:
    section.add "X-Amz-Date", valid_592997
  var valid_592998 = header.getOrDefault("X-Amz-Credential")
  valid_592998 = validateParameter(valid_592998, JString, required = false,
                                 default = nil)
  if valid_592998 != nil:
    section.add "X-Amz-Credential", valid_592998
  var valid_592999 = header.getOrDefault("X-Amz-Security-Token")
  valid_592999 = validateParameter(valid_592999, JString, required = false,
                                 default = nil)
  if valid_592999 != nil:
    section.add "X-Amz-Security-Token", valid_592999
  var valid_593000 = header.getOrDefault("X-Amz-Algorithm")
  valid_593000 = validateParameter(valid_593000, JString, required = false,
                                 default = nil)
  if valid_593000 != nil:
    section.add "X-Amz-Algorithm", valid_593000
  var valid_593001 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593001 = validateParameter(valid_593001, JString, required = false,
                                 default = nil)
  if valid_593001 != nil:
    section.add "X-Amz-SignedHeaders", valid_593001
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593002: Call_ListRoutes_592974; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of existing routes in a service mesh.
  ## 
  let valid = call_593002.validator(path, query, header, formData, body)
  let scheme = call_593002.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593002.url(scheme.get, call_593002.host, call_593002.base,
                         call_593002.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593002, url, valid)

proc call*(call_593003: Call_ListRoutes_592974; meshName: string;
          virtualRouterName: string; nextToken: string = ""; limit: int = 0): Recallable =
  ## listRoutes
  ## Returns a list of existing routes in a service mesh.
  ##   nextToken: string
  ##            : The <code>nextToken</code> value returned from a previous paginated
  ##             <code>ListRoutes</code> request where <code>limit</code> was used and the results
  ##          exceeded the value of that parameter. Pagination continues from the end of the previous
  ##          results that returned the <code>nextToken</code> value.
  ##   limit: int
  ##        : The maximum number of results returned by <code>ListRoutes</code> in paginated output.
  ##          When you use this parameter, <code>ListRoutes</code> returns only <code>limit</code>
  ##          results in a single page along with a <code>nextToken</code> response element. You can see
  ##          the remaining results of the initial request by sending another <code>ListRoutes</code>
  ##          request with the returned <code>nextToken</code> value. This value can be between
  ##          1 and 100. If you don't use this parameter,
  ##             <code>ListRoutes</code> returns up to 100 results and a
  ##             <code>nextToken</code> value if applicable.
  ##   meshName: string (required)
  ##           : The name of the service mesh to list routes in.
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router to list routes in.
  var path_593004 = newJObject()
  var query_593005 = newJObject()
  add(query_593005, "nextToken", newJString(nextToken))
  add(query_593005, "limit", newJInt(limit))
  add(path_593004, "meshName", newJString(meshName))
  add(path_593004, "virtualRouterName", newJString(virtualRouterName))
  result = call_593003.call(path_593004, query_593005, nil, nil, nil)

var listRoutes* = Call_ListRoutes_592974(name: "listRoutes",
                                      meth: HttpMethod.HttpGet,
                                      host: "appmesh.amazonaws.com", route: "/v20190125/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes",
                                      validator: validate_ListRoutes_592975,
                                      base: "/", url: url_ListRoutes_592976,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVirtualNode_593040 = ref object of OpenApiRestCall_592364
proc url_CreateVirtualNode_593042(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualNodes")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_CreateVirtualNode_593041(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Creates a virtual node within a service mesh.</p>
  ##          <p>A virtual node acts as a logical pointer to a particular task group, such as an Amazon ECS
  ##          service or a Kubernetes deployment. When you create a virtual node, you can specify the
  ##          service discovery information for your task group.</p>
  ##          <p>Any inbound traffic that your virtual node expects should be specified as a
  ##             <code>listener</code>. Any outbound traffic that your virtual node expects to reach
  ##          should be specified as a <code>backend</code>.</p>
  ##          <p>The response metadata for your new virtual node contains the <code>arn</code> that is
  ##          associated with the virtual node. Set this value (either the full ARN or the truncated
  ##          resource name: for example, <code>mesh/default/virtualNode/simpleapp</code>) as the
  ##             <code>APPMESH_VIRTUAL_NODE_NAME</code> environment variable for your task group's Envoy
  ##          proxy container in your task definition or pod spec. This is then mapped to the
  ##             <code>node.id</code> and <code>node.cluster</code> Envoy parameters.</p>
  ##          <note>
  ##             <p>If you require your Envoy stats or tracing to use a different name, you can override
  ##             the <code>node.cluster</code> value that is set by
  ##                <code>APPMESH_VIRTUAL_NODE_NAME</code> with the
  ##                <code>APPMESH_VIRTUAL_NODE_CLUSTER</code> environment variable.</p>
  ##          </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh to create the virtual node in.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_593043 = path.getOrDefault("meshName")
  valid_593043 = validateParameter(valid_593043, JString, required = true,
                                 default = nil)
  if valid_593043 != nil:
    section.add "meshName", valid_593043
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593044 = header.getOrDefault("X-Amz-Signature")
  valid_593044 = validateParameter(valid_593044, JString, required = false,
                                 default = nil)
  if valid_593044 != nil:
    section.add "X-Amz-Signature", valid_593044
  var valid_593045 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593045 = validateParameter(valid_593045, JString, required = false,
                                 default = nil)
  if valid_593045 != nil:
    section.add "X-Amz-Content-Sha256", valid_593045
  var valid_593046 = header.getOrDefault("X-Amz-Date")
  valid_593046 = validateParameter(valid_593046, JString, required = false,
                                 default = nil)
  if valid_593046 != nil:
    section.add "X-Amz-Date", valid_593046
  var valid_593047 = header.getOrDefault("X-Amz-Credential")
  valid_593047 = validateParameter(valid_593047, JString, required = false,
                                 default = nil)
  if valid_593047 != nil:
    section.add "X-Amz-Credential", valid_593047
  var valid_593048 = header.getOrDefault("X-Amz-Security-Token")
  valid_593048 = validateParameter(valid_593048, JString, required = false,
                                 default = nil)
  if valid_593048 != nil:
    section.add "X-Amz-Security-Token", valid_593048
  var valid_593049 = header.getOrDefault("X-Amz-Algorithm")
  valid_593049 = validateParameter(valid_593049, JString, required = false,
                                 default = nil)
  if valid_593049 != nil:
    section.add "X-Amz-Algorithm", valid_593049
  var valid_593050 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593050 = validateParameter(valid_593050, JString, required = false,
                                 default = nil)
  if valid_593050 != nil:
    section.add "X-Amz-SignedHeaders", valid_593050
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593052: Call_CreateVirtualNode_593040; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a virtual node within a service mesh.</p>
  ##          <p>A virtual node acts as a logical pointer to a particular task group, such as an Amazon ECS
  ##          service or a Kubernetes deployment. When you create a virtual node, you can specify the
  ##          service discovery information for your task group.</p>
  ##          <p>Any inbound traffic that your virtual node expects should be specified as a
  ##             <code>listener</code>. Any outbound traffic that your virtual node expects to reach
  ##          should be specified as a <code>backend</code>.</p>
  ##          <p>The response metadata for your new virtual node contains the <code>arn</code> that is
  ##          associated with the virtual node. Set this value (either the full ARN or the truncated
  ##          resource name: for example, <code>mesh/default/virtualNode/simpleapp</code>) as the
  ##             <code>APPMESH_VIRTUAL_NODE_NAME</code> environment variable for your task group's Envoy
  ##          proxy container in your task definition or pod spec. This is then mapped to the
  ##             <code>node.id</code> and <code>node.cluster</code> Envoy parameters.</p>
  ##          <note>
  ##             <p>If you require your Envoy stats or tracing to use a different name, you can override
  ##             the <code>node.cluster</code> value that is set by
  ##                <code>APPMESH_VIRTUAL_NODE_NAME</code> with the
  ##                <code>APPMESH_VIRTUAL_NODE_CLUSTER</code> environment variable.</p>
  ##          </note>
  ## 
  let valid = call_593052.validator(path, query, header, formData, body)
  let scheme = call_593052.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593052.url(scheme.get, call_593052.host, call_593052.base,
                         call_593052.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593052, url, valid)

proc call*(call_593053: Call_CreateVirtualNode_593040; meshName: string;
          body: JsonNode): Recallable =
  ## createVirtualNode
  ## <p>Creates a virtual node within a service mesh.</p>
  ##          <p>A virtual node acts as a logical pointer to a particular task group, such as an Amazon ECS
  ##          service or a Kubernetes deployment. When you create a virtual node, you can specify the
  ##          service discovery information for your task group.</p>
  ##          <p>Any inbound traffic that your virtual node expects should be specified as a
  ##             <code>listener</code>. Any outbound traffic that your virtual node expects to reach
  ##          should be specified as a <code>backend</code>.</p>
  ##          <p>The response metadata for your new virtual node contains the <code>arn</code> that is
  ##          associated with the virtual node. Set this value (either the full ARN or the truncated
  ##          resource name: for example, <code>mesh/default/virtualNode/simpleapp</code>) as the
  ##             <code>APPMESH_VIRTUAL_NODE_NAME</code> environment variable for your task group's Envoy
  ##          proxy container in your task definition or pod spec. This is then mapped to the
  ##             <code>node.id</code> and <code>node.cluster</code> Envoy parameters.</p>
  ##          <note>
  ##             <p>If you require your Envoy stats or tracing to use a different name, you can override
  ##             the <code>node.cluster</code> value that is set by
  ##                <code>APPMESH_VIRTUAL_NODE_NAME</code> with the
  ##                <code>APPMESH_VIRTUAL_NODE_CLUSTER</code> environment variable.</p>
  ##          </note>
  ##   meshName: string (required)
  ##           : The name of the service mesh to create the virtual node in.
  ##   body: JObject (required)
  var path_593054 = newJObject()
  var body_593055 = newJObject()
  add(path_593054, "meshName", newJString(meshName))
  if body != nil:
    body_593055 = body
  result = call_593053.call(path_593054, nil, nil, nil, body_593055)

var createVirtualNode* = Call_CreateVirtualNode_593040(name: "createVirtualNode",
    meth: HttpMethod.HttpPut, host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualNodes",
    validator: validate_CreateVirtualNode_593041, base: "/",
    url: url_CreateVirtualNode_593042, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVirtualNodes_593023 = ref object of OpenApiRestCall_592364
proc url_ListVirtualNodes_593025(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualNodes")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_ListVirtualNodes_593024(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Returns a list of existing virtual nodes.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh to list virtual nodes in.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_593026 = path.getOrDefault("meshName")
  valid_593026 = validateParameter(valid_593026, JString, required = true,
                                 default = nil)
  if valid_593026 != nil:
    section.add "meshName", valid_593026
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The <code>nextToken</code> value returned from a previous paginated
  ##             <code>ListVirtualNodes</code> request where <code>limit</code> was used and the results
  ##          exceeded the value of that parameter. Pagination continues from the end of the previous
  ##          results that returned the <code>nextToken</code> value.
  ##   limit: JInt
  ##        : The maximum number of results returned by <code>ListVirtualNodes</code> in paginated
  ##          output. When you use this parameter, <code>ListVirtualNodes</code> returns only
  ##             <code>limit</code> results in a single page along with a <code>nextToken</code> response
  ##          element. You can see the remaining results of the initial request by sending another
  ##             <code>ListVirtualNodes</code> request with the returned <code>nextToken</code> value.
  ##          This value can be between 1 and 100. If you don't use this
  ##          parameter, <code>ListVirtualNodes</code> returns up to 100 results and a
  ##             <code>nextToken</code> value if applicable.
  section = newJObject()
  var valid_593027 = query.getOrDefault("nextToken")
  valid_593027 = validateParameter(valid_593027, JString, required = false,
                                 default = nil)
  if valid_593027 != nil:
    section.add "nextToken", valid_593027
  var valid_593028 = query.getOrDefault("limit")
  valid_593028 = validateParameter(valid_593028, JInt, required = false, default = nil)
  if valid_593028 != nil:
    section.add "limit", valid_593028
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593029 = header.getOrDefault("X-Amz-Signature")
  valid_593029 = validateParameter(valid_593029, JString, required = false,
                                 default = nil)
  if valid_593029 != nil:
    section.add "X-Amz-Signature", valid_593029
  var valid_593030 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593030 = validateParameter(valid_593030, JString, required = false,
                                 default = nil)
  if valid_593030 != nil:
    section.add "X-Amz-Content-Sha256", valid_593030
  var valid_593031 = header.getOrDefault("X-Amz-Date")
  valid_593031 = validateParameter(valid_593031, JString, required = false,
                                 default = nil)
  if valid_593031 != nil:
    section.add "X-Amz-Date", valid_593031
  var valid_593032 = header.getOrDefault("X-Amz-Credential")
  valid_593032 = validateParameter(valid_593032, JString, required = false,
                                 default = nil)
  if valid_593032 != nil:
    section.add "X-Amz-Credential", valid_593032
  var valid_593033 = header.getOrDefault("X-Amz-Security-Token")
  valid_593033 = validateParameter(valid_593033, JString, required = false,
                                 default = nil)
  if valid_593033 != nil:
    section.add "X-Amz-Security-Token", valid_593033
  var valid_593034 = header.getOrDefault("X-Amz-Algorithm")
  valid_593034 = validateParameter(valid_593034, JString, required = false,
                                 default = nil)
  if valid_593034 != nil:
    section.add "X-Amz-Algorithm", valid_593034
  var valid_593035 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593035 = validateParameter(valid_593035, JString, required = false,
                                 default = nil)
  if valid_593035 != nil:
    section.add "X-Amz-SignedHeaders", valid_593035
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593036: Call_ListVirtualNodes_593023; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of existing virtual nodes.
  ## 
  let valid = call_593036.validator(path, query, header, formData, body)
  let scheme = call_593036.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593036.url(scheme.get, call_593036.host, call_593036.base,
                         call_593036.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593036, url, valid)

proc call*(call_593037: Call_ListVirtualNodes_593023; meshName: string;
          nextToken: string = ""; limit: int = 0): Recallable =
  ## listVirtualNodes
  ## Returns a list of existing virtual nodes.
  ##   nextToken: string
  ##            : The <code>nextToken</code> value returned from a previous paginated
  ##             <code>ListVirtualNodes</code> request where <code>limit</code> was used and the results
  ##          exceeded the value of that parameter. Pagination continues from the end of the previous
  ##          results that returned the <code>nextToken</code> value.
  ##   limit: int
  ##        : The maximum number of results returned by <code>ListVirtualNodes</code> in paginated
  ##          output. When you use this parameter, <code>ListVirtualNodes</code> returns only
  ##             <code>limit</code> results in a single page along with a <code>nextToken</code> response
  ##          element. You can see the remaining results of the initial request by sending another
  ##             <code>ListVirtualNodes</code> request with the returned <code>nextToken</code> value.
  ##          This value can be between 1 and 100. If you don't use this
  ##          parameter, <code>ListVirtualNodes</code> returns up to 100 results and a
  ##             <code>nextToken</code> value if applicable.
  ##   meshName: string (required)
  ##           : The name of the service mesh to list virtual nodes in.
  var path_593038 = newJObject()
  var query_593039 = newJObject()
  add(query_593039, "nextToken", newJString(nextToken))
  add(query_593039, "limit", newJInt(limit))
  add(path_593038, "meshName", newJString(meshName))
  result = call_593037.call(path_593038, query_593039, nil, nil, nil)

var listVirtualNodes* = Call_ListVirtualNodes_593023(name: "listVirtualNodes",
    meth: HttpMethod.HttpGet, host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualNodes",
    validator: validate_ListVirtualNodes_593024, base: "/",
    url: url_ListVirtualNodes_593025, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVirtualRouter_593073 = ref object of OpenApiRestCall_592364
proc url_CreateVirtualRouter_593075(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualRouters")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_CreateVirtualRouter_593074(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Creates a virtual router within a service mesh.</p>
  ##          <p>Any inbound traffic that your virtual router expects should be specified as a
  ##             <code>listener</code>. </p>
  ##          <p>Virtual routers handle traffic for one or more virtual services within your mesh. After
  ##          you create your virtual router, create and associate routes for your virtual router that
  ##          direct incoming requests to different virtual nodes.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh to create the virtual router in.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_593076 = path.getOrDefault("meshName")
  valid_593076 = validateParameter(valid_593076, JString, required = true,
                                 default = nil)
  if valid_593076 != nil:
    section.add "meshName", valid_593076
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593077 = header.getOrDefault("X-Amz-Signature")
  valid_593077 = validateParameter(valid_593077, JString, required = false,
                                 default = nil)
  if valid_593077 != nil:
    section.add "X-Amz-Signature", valid_593077
  var valid_593078 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593078 = validateParameter(valid_593078, JString, required = false,
                                 default = nil)
  if valid_593078 != nil:
    section.add "X-Amz-Content-Sha256", valid_593078
  var valid_593079 = header.getOrDefault("X-Amz-Date")
  valid_593079 = validateParameter(valid_593079, JString, required = false,
                                 default = nil)
  if valid_593079 != nil:
    section.add "X-Amz-Date", valid_593079
  var valid_593080 = header.getOrDefault("X-Amz-Credential")
  valid_593080 = validateParameter(valid_593080, JString, required = false,
                                 default = nil)
  if valid_593080 != nil:
    section.add "X-Amz-Credential", valid_593080
  var valid_593081 = header.getOrDefault("X-Amz-Security-Token")
  valid_593081 = validateParameter(valid_593081, JString, required = false,
                                 default = nil)
  if valid_593081 != nil:
    section.add "X-Amz-Security-Token", valid_593081
  var valid_593082 = header.getOrDefault("X-Amz-Algorithm")
  valid_593082 = validateParameter(valid_593082, JString, required = false,
                                 default = nil)
  if valid_593082 != nil:
    section.add "X-Amz-Algorithm", valid_593082
  var valid_593083 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593083 = validateParameter(valid_593083, JString, required = false,
                                 default = nil)
  if valid_593083 != nil:
    section.add "X-Amz-SignedHeaders", valid_593083
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593085: Call_CreateVirtualRouter_593073; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a virtual router within a service mesh.</p>
  ##          <p>Any inbound traffic that your virtual router expects should be specified as a
  ##             <code>listener</code>. </p>
  ##          <p>Virtual routers handle traffic for one or more virtual services within your mesh. After
  ##          you create your virtual router, create and associate routes for your virtual router that
  ##          direct incoming requests to different virtual nodes.</p>
  ## 
  let valid = call_593085.validator(path, query, header, formData, body)
  let scheme = call_593085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593085.url(scheme.get, call_593085.host, call_593085.base,
                         call_593085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593085, url, valid)

proc call*(call_593086: Call_CreateVirtualRouter_593073; meshName: string;
          body: JsonNode): Recallable =
  ## createVirtualRouter
  ## <p>Creates a virtual router within a service mesh.</p>
  ##          <p>Any inbound traffic that your virtual router expects should be specified as a
  ##             <code>listener</code>. </p>
  ##          <p>Virtual routers handle traffic for one or more virtual services within your mesh. After
  ##          you create your virtual router, create and associate routes for your virtual router that
  ##          direct incoming requests to different virtual nodes.</p>
  ##   meshName: string (required)
  ##           : The name of the service mesh to create the virtual router in.
  ##   body: JObject (required)
  var path_593087 = newJObject()
  var body_593088 = newJObject()
  add(path_593087, "meshName", newJString(meshName))
  if body != nil:
    body_593088 = body
  result = call_593086.call(path_593087, nil, nil, nil, body_593088)

var createVirtualRouter* = Call_CreateVirtualRouter_593073(
    name: "createVirtualRouter", meth: HttpMethod.HttpPut,
    host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualRouters",
    validator: validate_CreateVirtualRouter_593074, base: "/",
    url: url_CreateVirtualRouter_593075, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVirtualRouters_593056 = ref object of OpenApiRestCall_592364
proc url_ListVirtualRouters_593058(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualRouters")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_ListVirtualRouters_593057(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Returns a list of existing virtual routers in a service mesh.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh to list virtual routers in.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_593059 = path.getOrDefault("meshName")
  valid_593059 = validateParameter(valid_593059, JString, required = true,
                                 default = nil)
  if valid_593059 != nil:
    section.add "meshName", valid_593059
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The <code>nextToken</code> value returned from a previous paginated
  ##             <code>ListVirtualRouters</code> request where <code>limit</code> was used and the
  ##          results exceeded the value of that parameter. Pagination continues from the end of the
  ##          previous results that returned the <code>nextToken</code> value.
  ##   limit: JInt
  ##        : The maximum number of results returned by <code>ListVirtualRouters</code> in paginated
  ##          output. When you use this parameter, <code>ListVirtualRouters</code> returns only
  ##             <code>limit</code> results in a single page along with a <code>nextToken</code> response
  ##          element. You can see the remaining results of the initial request by sending another
  ##             <code>ListVirtualRouters</code> request with the returned <code>nextToken</code> value.
  ##          This value can be between 1 and 100. If you don't use this
  ##          parameter, <code>ListVirtualRouters</code> returns up to 100 results and
  ##          a <code>nextToken</code> value if applicable.
  section = newJObject()
  var valid_593060 = query.getOrDefault("nextToken")
  valid_593060 = validateParameter(valid_593060, JString, required = false,
                                 default = nil)
  if valid_593060 != nil:
    section.add "nextToken", valid_593060
  var valid_593061 = query.getOrDefault("limit")
  valid_593061 = validateParameter(valid_593061, JInt, required = false, default = nil)
  if valid_593061 != nil:
    section.add "limit", valid_593061
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593062 = header.getOrDefault("X-Amz-Signature")
  valid_593062 = validateParameter(valid_593062, JString, required = false,
                                 default = nil)
  if valid_593062 != nil:
    section.add "X-Amz-Signature", valid_593062
  var valid_593063 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593063 = validateParameter(valid_593063, JString, required = false,
                                 default = nil)
  if valid_593063 != nil:
    section.add "X-Amz-Content-Sha256", valid_593063
  var valid_593064 = header.getOrDefault("X-Amz-Date")
  valid_593064 = validateParameter(valid_593064, JString, required = false,
                                 default = nil)
  if valid_593064 != nil:
    section.add "X-Amz-Date", valid_593064
  var valid_593065 = header.getOrDefault("X-Amz-Credential")
  valid_593065 = validateParameter(valid_593065, JString, required = false,
                                 default = nil)
  if valid_593065 != nil:
    section.add "X-Amz-Credential", valid_593065
  var valid_593066 = header.getOrDefault("X-Amz-Security-Token")
  valid_593066 = validateParameter(valid_593066, JString, required = false,
                                 default = nil)
  if valid_593066 != nil:
    section.add "X-Amz-Security-Token", valid_593066
  var valid_593067 = header.getOrDefault("X-Amz-Algorithm")
  valid_593067 = validateParameter(valid_593067, JString, required = false,
                                 default = nil)
  if valid_593067 != nil:
    section.add "X-Amz-Algorithm", valid_593067
  var valid_593068 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593068 = validateParameter(valid_593068, JString, required = false,
                                 default = nil)
  if valid_593068 != nil:
    section.add "X-Amz-SignedHeaders", valid_593068
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593069: Call_ListVirtualRouters_593056; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of existing virtual routers in a service mesh.
  ## 
  let valid = call_593069.validator(path, query, header, formData, body)
  let scheme = call_593069.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593069.url(scheme.get, call_593069.host, call_593069.base,
                         call_593069.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593069, url, valid)

proc call*(call_593070: Call_ListVirtualRouters_593056; meshName: string;
          nextToken: string = ""; limit: int = 0): Recallable =
  ## listVirtualRouters
  ## Returns a list of existing virtual routers in a service mesh.
  ##   nextToken: string
  ##            : The <code>nextToken</code> value returned from a previous paginated
  ##             <code>ListVirtualRouters</code> request where <code>limit</code> was used and the
  ##          results exceeded the value of that parameter. Pagination continues from the end of the
  ##          previous results that returned the <code>nextToken</code> value.
  ##   limit: int
  ##        : The maximum number of results returned by <code>ListVirtualRouters</code> in paginated
  ##          output. When you use this parameter, <code>ListVirtualRouters</code> returns only
  ##             <code>limit</code> results in a single page along with a <code>nextToken</code> response
  ##          element. You can see the remaining results of the initial request by sending another
  ##             <code>ListVirtualRouters</code> request with the returned <code>nextToken</code> value.
  ##          This value can be between 1 and 100. If you don't use this
  ##          parameter, <code>ListVirtualRouters</code> returns up to 100 results and
  ##          a <code>nextToken</code> value if applicable.
  ##   meshName: string (required)
  ##           : The name of the service mesh to list virtual routers in.
  var path_593071 = newJObject()
  var query_593072 = newJObject()
  add(query_593072, "nextToken", newJString(nextToken))
  add(query_593072, "limit", newJInt(limit))
  add(path_593071, "meshName", newJString(meshName))
  result = call_593070.call(path_593071, query_593072, nil, nil, nil)

var listVirtualRouters* = Call_ListVirtualRouters_593056(
    name: "listVirtualRouters", meth: HttpMethod.HttpGet,
    host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualRouters",
    validator: validate_ListVirtualRouters_593057, base: "/",
    url: url_ListVirtualRouters_593058, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVirtualService_593106 = ref object of OpenApiRestCall_592364
proc url_CreateVirtualService_593108(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualServices")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_CreateVirtualService_593107(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a virtual service within a service mesh.</p>
  ##          <p>A virtual service is an abstraction of a real service that is provided by a virtual node
  ##          directly or indirectly by means of a virtual router. Dependent services call your virtual
  ##          service by its <code>virtualServiceName</code>, and those requests are routed to the
  ##          virtual node or virtual router that is specified as the provider for the virtual
  ##          service.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh to create the virtual service in.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_593109 = path.getOrDefault("meshName")
  valid_593109 = validateParameter(valid_593109, JString, required = true,
                                 default = nil)
  if valid_593109 != nil:
    section.add "meshName", valid_593109
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593110 = header.getOrDefault("X-Amz-Signature")
  valid_593110 = validateParameter(valid_593110, JString, required = false,
                                 default = nil)
  if valid_593110 != nil:
    section.add "X-Amz-Signature", valid_593110
  var valid_593111 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593111 = validateParameter(valid_593111, JString, required = false,
                                 default = nil)
  if valid_593111 != nil:
    section.add "X-Amz-Content-Sha256", valid_593111
  var valid_593112 = header.getOrDefault("X-Amz-Date")
  valid_593112 = validateParameter(valid_593112, JString, required = false,
                                 default = nil)
  if valid_593112 != nil:
    section.add "X-Amz-Date", valid_593112
  var valid_593113 = header.getOrDefault("X-Amz-Credential")
  valid_593113 = validateParameter(valid_593113, JString, required = false,
                                 default = nil)
  if valid_593113 != nil:
    section.add "X-Amz-Credential", valid_593113
  var valid_593114 = header.getOrDefault("X-Amz-Security-Token")
  valid_593114 = validateParameter(valid_593114, JString, required = false,
                                 default = nil)
  if valid_593114 != nil:
    section.add "X-Amz-Security-Token", valid_593114
  var valid_593115 = header.getOrDefault("X-Amz-Algorithm")
  valid_593115 = validateParameter(valid_593115, JString, required = false,
                                 default = nil)
  if valid_593115 != nil:
    section.add "X-Amz-Algorithm", valid_593115
  var valid_593116 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593116 = validateParameter(valid_593116, JString, required = false,
                                 default = nil)
  if valid_593116 != nil:
    section.add "X-Amz-SignedHeaders", valid_593116
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593118: Call_CreateVirtualService_593106; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a virtual service within a service mesh.</p>
  ##          <p>A virtual service is an abstraction of a real service that is provided by a virtual node
  ##          directly or indirectly by means of a virtual router. Dependent services call your virtual
  ##          service by its <code>virtualServiceName</code>, and those requests are routed to the
  ##          virtual node or virtual router that is specified as the provider for the virtual
  ##          service.</p>
  ## 
  let valid = call_593118.validator(path, query, header, formData, body)
  let scheme = call_593118.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593118.url(scheme.get, call_593118.host, call_593118.base,
                         call_593118.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593118, url, valid)

proc call*(call_593119: Call_CreateVirtualService_593106; meshName: string;
          body: JsonNode): Recallable =
  ## createVirtualService
  ## <p>Creates a virtual service within a service mesh.</p>
  ##          <p>A virtual service is an abstraction of a real service that is provided by a virtual node
  ##          directly or indirectly by means of a virtual router. Dependent services call your virtual
  ##          service by its <code>virtualServiceName</code>, and those requests are routed to the
  ##          virtual node or virtual router that is specified as the provider for the virtual
  ##          service.</p>
  ##   meshName: string (required)
  ##           : The name of the service mesh to create the virtual service in.
  ##   body: JObject (required)
  var path_593120 = newJObject()
  var body_593121 = newJObject()
  add(path_593120, "meshName", newJString(meshName))
  if body != nil:
    body_593121 = body
  result = call_593119.call(path_593120, nil, nil, nil, body_593121)

var createVirtualService* = Call_CreateVirtualService_593106(
    name: "createVirtualService", meth: HttpMethod.HttpPut,
    host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualServices",
    validator: validate_CreateVirtualService_593107, base: "/",
    url: url_CreateVirtualService_593108, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVirtualServices_593089 = ref object of OpenApiRestCall_592364
proc url_ListVirtualServices_593091(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualServices")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_ListVirtualServices_593090(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Returns a list of existing virtual services in a service mesh.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh to list virtual services in.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_593092 = path.getOrDefault("meshName")
  valid_593092 = validateParameter(valid_593092, JString, required = true,
                                 default = nil)
  if valid_593092 != nil:
    section.add "meshName", valid_593092
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The <code>nextToken</code> value returned from a previous paginated
  ##             <code>ListVirtualServices</code> request where <code>limit</code> was used and the
  ##          results exceeded the value of that parameter. Pagination continues from the end of the
  ##          previous results that returned the <code>nextToken</code> value.
  ##   limit: JInt
  ##        : The maximum number of results returned by <code>ListVirtualServices</code> in paginated
  ##          output. When you use this parameter, <code>ListVirtualServices</code> returns only
  ##             <code>limit</code> results in a single page along with a <code>nextToken</code> response
  ##          element. You can see the remaining results of the initial request by sending another
  ##             <code>ListVirtualServices</code> request with the returned <code>nextToken</code> value.
  ##          This value can be between 1 and 100. If you don't use this
  ##          parameter, <code>ListVirtualServices</code> returns up to 100 results and
  ##          a <code>nextToken</code> value if applicable.
  section = newJObject()
  var valid_593093 = query.getOrDefault("nextToken")
  valid_593093 = validateParameter(valid_593093, JString, required = false,
                                 default = nil)
  if valid_593093 != nil:
    section.add "nextToken", valid_593093
  var valid_593094 = query.getOrDefault("limit")
  valid_593094 = validateParameter(valid_593094, JInt, required = false, default = nil)
  if valid_593094 != nil:
    section.add "limit", valid_593094
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593095 = header.getOrDefault("X-Amz-Signature")
  valid_593095 = validateParameter(valid_593095, JString, required = false,
                                 default = nil)
  if valid_593095 != nil:
    section.add "X-Amz-Signature", valid_593095
  var valid_593096 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593096 = validateParameter(valid_593096, JString, required = false,
                                 default = nil)
  if valid_593096 != nil:
    section.add "X-Amz-Content-Sha256", valid_593096
  var valid_593097 = header.getOrDefault("X-Amz-Date")
  valid_593097 = validateParameter(valid_593097, JString, required = false,
                                 default = nil)
  if valid_593097 != nil:
    section.add "X-Amz-Date", valid_593097
  var valid_593098 = header.getOrDefault("X-Amz-Credential")
  valid_593098 = validateParameter(valid_593098, JString, required = false,
                                 default = nil)
  if valid_593098 != nil:
    section.add "X-Amz-Credential", valid_593098
  var valid_593099 = header.getOrDefault("X-Amz-Security-Token")
  valid_593099 = validateParameter(valid_593099, JString, required = false,
                                 default = nil)
  if valid_593099 != nil:
    section.add "X-Amz-Security-Token", valid_593099
  var valid_593100 = header.getOrDefault("X-Amz-Algorithm")
  valid_593100 = validateParameter(valid_593100, JString, required = false,
                                 default = nil)
  if valid_593100 != nil:
    section.add "X-Amz-Algorithm", valid_593100
  var valid_593101 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593101 = validateParameter(valid_593101, JString, required = false,
                                 default = nil)
  if valid_593101 != nil:
    section.add "X-Amz-SignedHeaders", valid_593101
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593102: Call_ListVirtualServices_593089; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of existing virtual services in a service mesh.
  ## 
  let valid = call_593102.validator(path, query, header, formData, body)
  let scheme = call_593102.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593102.url(scheme.get, call_593102.host, call_593102.base,
                         call_593102.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593102, url, valid)

proc call*(call_593103: Call_ListVirtualServices_593089; meshName: string;
          nextToken: string = ""; limit: int = 0): Recallable =
  ## listVirtualServices
  ## Returns a list of existing virtual services in a service mesh.
  ##   nextToken: string
  ##            : The <code>nextToken</code> value returned from a previous paginated
  ##             <code>ListVirtualServices</code> request where <code>limit</code> was used and the
  ##          results exceeded the value of that parameter. Pagination continues from the end of the
  ##          previous results that returned the <code>nextToken</code> value.
  ##   limit: int
  ##        : The maximum number of results returned by <code>ListVirtualServices</code> in paginated
  ##          output. When you use this parameter, <code>ListVirtualServices</code> returns only
  ##             <code>limit</code> results in a single page along with a <code>nextToken</code> response
  ##          element. You can see the remaining results of the initial request by sending another
  ##             <code>ListVirtualServices</code> request with the returned <code>nextToken</code> value.
  ##          This value can be between 1 and 100. If you don't use this
  ##          parameter, <code>ListVirtualServices</code> returns up to 100 results and
  ##          a <code>nextToken</code> value if applicable.
  ##   meshName: string (required)
  ##           : The name of the service mesh to list virtual services in.
  var path_593104 = newJObject()
  var query_593105 = newJObject()
  add(query_593105, "nextToken", newJString(nextToken))
  add(query_593105, "limit", newJInt(limit))
  add(path_593104, "meshName", newJString(meshName))
  result = call_593103.call(path_593104, query_593105, nil, nil, nil)

var listVirtualServices* = Call_ListVirtualServices_593089(
    name: "listVirtualServices", meth: HttpMethod.HttpGet,
    host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualServices",
    validator: validate_ListVirtualServices_593090, base: "/",
    url: url_ListVirtualServices_593091, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMesh_593136 = ref object of OpenApiRestCall_592364
proc url_UpdateMesh_593138(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UpdateMesh_593137(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates an existing service mesh.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh to update.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_593139 = path.getOrDefault("meshName")
  valid_593139 = validateParameter(valid_593139, JString, required = true,
                                 default = nil)
  if valid_593139 != nil:
    section.add "meshName", valid_593139
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593140 = header.getOrDefault("X-Amz-Signature")
  valid_593140 = validateParameter(valid_593140, JString, required = false,
                                 default = nil)
  if valid_593140 != nil:
    section.add "X-Amz-Signature", valid_593140
  var valid_593141 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593141 = validateParameter(valid_593141, JString, required = false,
                                 default = nil)
  if valid_593141 != nil:
    section.add "X-Amz-Content-Sha256", valid_593141
  var valid_593142 = header.getOrDefault("X-Amz-Date")
  valid_593142 = validateParameter(valid_593142, JString, required = false,
                                 default = nil)
  if valid_593142 != nil:
    section.add "X-Amz-Date", valid_593142
  var valid_593143 = header.getOrDefault("X-Amz-Credential")
  valid_593143 = validateParameter(valid_593143, JString, required = false,
                                 default = nil)
  if valid_593143 != nil:
    section.add "X-Amz-Credential", valid_593143
  var valid_593144 = header.getOrDefault("X-Amz-Security-Token")
  valid_593144 = validateParameter(valid_593144, JString, required = false,
                                 default = nil)
  if valid_593144 != nil:
    section.add "X-Amz-Security-Token", valid_593144
  var valid_593145 = header.getOrDefault("X-Amz-Algorithm")
  valid_593145 = validateParameter(valid_593145, JString, required = false,
                                 default = nil)
  if valid_593145 != nil:
    section.add "X-Amz-Algorithm", valid_593145
  var valid_593146 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593146 = validateParameter(valid_593146, JString, required = false,
                                 default = nil)
  if valid_593146 != nil:
    section.add "X-Amz-SignedHeaders", valid_593146
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593148: Call_UpdateMesh_593136; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing service mesh.
  ## 
  let valid = call_593148.validator(path, query, header, formData, body)
  let scheme = call_593148.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593148.url(scheme.get, call_593148.host, call_593148.base,
                         call_593148.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593148, url, valid)

proc call*(call_593149: Call_UpdateMesh_593136; meshName: string; body: JsonNode): Recallable =
  ## updateMesh
  ## Updates an existing service mesh.
  ##   meshName: string (required)
  ##           : The name of the service mesh to update.
  ##   body: JObject (required)
  var path_593150 = newJObject()
  var body_593151 = newJObject()
  add(path_593150, "meshName", newJString(meshName))
  if body != nil:
    body_593151 = body
  result = call_593149.call(path_593150, nil, nil, nil, body_593151)

var updateMesh* = Call_UpdateMesh_593136(name: "updateMesh",
                                      meth: HttpMethod.HttpPut,
                                      host: "appmesh.amazonaws.com",
                                      route: "/v20190125/meshes/{meshName}",
                                      validator: validate_UpdateMesh_593137,
                                      base: "/", url: url_UpdateMesh_593138,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMesh_593122 = ref object of OpenApiRestCall_592364
proc url_DescribeMesh_593124(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DescribeMesh_593123(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes an existing service mesh.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh to describe.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_593125 = path.getOrDefault("meshName")
  valid_593125 = validateParameter(valid_593125, JString, required = true,
                                 default = nil)
  if valid_593125 != nil:
    section.add "meshName", valid_593125
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593126 = header.getOrDefault("X-Amz-Signature")
  valid_593126 = validateParameter(valid_593126, JString, required = false,
                                 default = nil)
  if valid_593126 != nil:
    section.add "X-Amz-Signature", valid_593126
  var valid_593127 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593127 = validateParameter(valid_593127, JString, required = false,
                                 default = nil)
  if valid_593127 != nil:
    section.add "X-Amz-Content-Sha256", valid_593127
  var valid_593128 = header.getOrDefault("X-Amz-Date")
  valid_593128 = validateParameter(valid_593128, JString, required = false,
                                 default = nil)
  if valid_593128 != nil:
    section.add "X-Amz-Date", valid_593128
  var valid_593129 = header.getOrDefault("X-Amz-Credential")
  valid_593129 = validateParameter(valid_593129, JString, required = false,
                                 default = nil)
  if valid_593129 != nil:
    section.add "X-Amz-Credential", valid_593129
  var valid_593130 = header.getOrDefault("X-Amz-Security-Token")
  valid_593130 = validateParameter(valid_593130, JString, required = false,
                                 default = nil)
  if valid_593130 != nil:
    section.add "X-Amz-Security-Token", valid_593130
  var valid_593131 = header.getOrDefault("X-Amz-Algorithm")
  valid_593131 = validateParameter(valid_593131, JString, required = false,
                                 default = nil)
  if valid_593131 != nil:
    section.add "X-Amz-Algorithm", valid_593131
  var valid_593132 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593132 = validateParameter(valid_593132, JString, required = false,
                                 default = nil)
  if valid_593132 != nil:
    section.add "X-Amz-SignedHeaders", valid_593132
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593133: Call_DescribeMesh_593122; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an existing service mesh.
  ## 
  let valid = call_593133.validator(path, query, header, formData, body)
  let scheme = call_593133.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593133.url(scheme.get, call_593133.host, call_593133.base,
                         call_593133.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593133, url, valid)

proc call*(call_593134: Call_DescribeMesh_593122; meshName: string): Recallable =
  ## describeMesh
  ## Describes an existing service mesh.
  ##   meshName: string (required)
  ##           : The name of the service mesh to describe.
  var path_593135 = newJObject()
  add(path_593135, "meshName", newJString(meshName))
  result = call_593134.call(path_593135, nil, nil, nil, nil)

var describeMesh* = Call_DescribeMesh_593122(name: "describeMesh",
    meth: HttpMethod.HttpGet, host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}", validator: validate_DescribeMesh_593123,
    base: "/", url: url_DescribeMesh_593124, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMesh_593152 = ref object of OpenApiRestCall_592364
proc url_DeleteMesh_593154(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteMesh_593153(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes an existing service mesh.</p>
  ##          <p>You must delete all resources (virtual services, routes, virtual routers, and virtual
  ##          nodes) in the service mesh before you can delete the mesh itself.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_593155 = path.getOrDefault("meshName")
  valid_593155 = validateParameter(valid_593155, JString, required = true,
                                 default = nil)
  if valid_593155 != nil:
    section.add "meshName", valid_593155
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593156 = header.getOrDefault("X-Amz-Signature")
  valid_593156 = validateParameter(valid_593156, JString, required = false,
                                 default = nil)
  if valid_593156 != nil:
    section.add "X-Amz-Signature", valid_593156
  var valid_593157 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593157 = validateParameter(valid_593157, JString, required = false,
                                 default = nil)
  if valid_593157 != nil:
    section.add "X-Amz-Content-Sha256", valid_593157
  var valid_593158 = header.getOrDefault("X-Amz-Date")
  valid_593158 = validateParameter(valid_593158, JString, required = false,
                                 default = nil)
  if valid_593158 != nil:
    section.add "X-Amz-Date", valid_593158
  var valid_593159 = header.getOrDefault("X-Amz-Credential")
  valid_593159 = validateParameter(valid_593159, JString, required = false,
                                 default = nil)
  if valid_593159 != nil:
    section.add "X-Amz-Credential", valid_593159
  var valid_593160 = header.getOrDefault("X-Amz-Security-Token")
  valid_593160 = validateParameter(valid_593160, JString, required = false,
                                 default = nil)
  if valid_593160 != nil:
    section.add "X-Amz-Security-Token", valid_593160
  var valid_593161 = header.getOrDefault("X-Amz-Algorithm")
  valid_593161 = validateParameter(valid_593161, JString, required = false,
                                 default = nil)
  if valid_593161 != nil:
    section.add "X-Amz-Algorithm", valid_593161
  var valid_593162 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593162 = validateParameter(valid_593162, JString, required = false,
                                 default = nil)
  if valid_593162 != nil:
    section.add "X-Amz-SignedHeaders", valid_593162
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593163: Call_DeleteMesh_593152; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an existing service mesh.</p>
  ##          <p>You must delete all resources (virtual services, routes, virtual routers, and virtual
  ##          nodes) in the service mesh before you can delete the mesh itself.</p>
  ## 
  let valid = call_593163.validator(path, query, header, formData, body)
  let scheme = call_593163.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593163.url(scheme.get, call_593163.host, call_593163.base,
                         call_593163.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593163, url, valid)

proc call*(call_593164: Call_DeleteMesh_593152; meshName: string): Recallable =
  ## deleteMesh
  ## <p>Deletes an existing service mesh.</p>
  ##          <p>You must delete all resources (virtual services, routes, virtual routers, and virtual
  ##          nodes) in the service mesh before you can delete the mesh itself.</p>
  ##   meshName: string (required)
  ##           : The name of the service mesh to delete.
  var path_593165 = newJObject()
  add(path_593165, "meshName", newJString(meshName))
  result = call_593164.call(path_593165, nil, nil, nil, nil)

var deleteMesh* = Call_DeleteMesh_593152(name: "deleteMesh",
                                      meth: HttpMethod.HttpDelete,
                                      host: "appmesh.amazonaws.com",
                                      route: "/v20190125/meshes/{meshName}",
                                      validator: validate_DeleteMesh_593153,
                                      base: "/", url: url_DeleteMesh_593154,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRoute_593182 = ref object of OpenApiRestCall_592364
proc url_UpdateRoute_593184(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  assert "virtualRouterName" in path,
        "`virtualRouterName` is a required path parameter"
  assert "routeName" in path, "`routeName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualRouter/"),
               (kind: VariableSegment, value: "virtualRouterName"),
               (kind: ConstantSegment, value: "/routes/"),
               (kind: VariableSegment, value: "routeName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UpdateRoute_593183(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates an existing route for a specified service mesh and virtual router.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   routeName: JString (required)
  ##            : The name of the route to update.
  ##   meshName: JString (required)
  ##           : The name of the service mesh that the route resides in.
  ##   virtualRouterName: JString (required)
  ##                    : The name of the virtual router that the route is associated with.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `routeName` field"
  var valid_593185 = path.getOrDefault("routeName")
  valid_593185 = validateParameter(valid_593185, JString, required = true,
                                 default = nil)
  if valid_593185 != nil:
    section.add "routeName", valid_593185
  var valid_593186 = path.getOrDefault("meshName")
  valid_593186 = validateParameter(valid_593186, JString, required = true,
                                 default = nil)
  if valid_593186 != nil:
    section.add "meshName", valid_593186
  var valid_593187 = path.getOrDefault("virtualRouterName")
  valid_593187 = validateParameter(valid_593187, JString, required = true,
                                 default = nil)
  if valid_593187 != nil:
    section.add "virtualRouterName", valid_593187
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593188 = header.getOrDefault("X-Amz-Signature")
  valid_593188 = validateParameter(valid_593188, JString, required = false,
                                 default = nil)
  if valid_593188 != nil:
    section.add "X-Amz-Signature", valid_593188
  var valid_593189 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593189 = validateParameter(valid_593189, JString, required = false,
                                 default = nil)
  if valid_593189 != nil:
    section.add "X-Amz-Content-Sha256", valid_593189
  var valid_593190 = header.getOrDefault("X-Amz-Date")
  valid_593190 = validateParameter(valid_593190, JString, required = false,
                                 default = nil)
  if valid_593190 != nil:
    section.add "X-Amz-Date", valid_593190
  var valid_593191 = header.getOrDefault("X-Amz-Credential")
  valid_593191 = validateParameter(valid_593191, JString, required = false,
                                 default = nil)
  if valid_593191 != nil:
    section.add "X-Amz-Credential", valid_593191
  var valid_593192 = header.getOrDefault("X-Amz-Security-Token")
  valid_593192 = validateParameter(valid_593192, JString, required = false,
                                 default = nil)
  if valid_593192 != nil:
    section.add "X-Amz-Security-Token", valid_593192
  var valid_593193 = header.getOrDefault("X-Amz-Algorithm")
  valid_593193 = validateParameter(valid_593193, JString, required = false,
                                 default = nil)
  if valid_593193 != nil:
    section.add "X-Amz-Algorithm", valid_593193
  var valid_593194 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593194 = validateParameter(valid_593194, JString, required = false,
                                 default = nil)
  if valid_593194 != nil:
    section.add "X-Amz-SignedHeaders", valid_593194
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593196: Call_UpdateRoute_593182; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing route for a specified service mesh and virtual router.
  ## 
  let valid = call_593196.validator(path, query, header, formData, body)
  let scheme = call_593196.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593196.url(scheme.get, call_593196.host, call_593196.base,
                         call_593196.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593196, url, valid)

proc call*(call_593197: Call_UpdateRoute_593182; routeName: string; meshName: string;
          body: JsonNode; virtualRouterName: string): Recallable =
  ## updateRoute
  ## Updates an existing route for a specified service mesh and virtual router.
  ##   routeName: string (required)
  ##            : The name of the route to update.
  ##   meshName: string (required)
  ##           : The name of the service mesh that the route resides in.
  ##   body: JObject (required)
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router that the route is associated with.
  var path_593198 = newJObject()
  var body_593199 = newJObject()
  add(path_593198, "routeName", newJString(routeName))
  add(path_593198, "meshName", newJString(meshName))
  if body != nil:
    body_593199 = body
  add(path_593198, "virtualRouterName", newJString(virtualRouterName))
  result = call_593197.call(path_593198, nil, nil, nil, body_593199)

var updateRoute* = Call_UpdateRoute_593182(name: "updateRoute",
                                        meth: HttpMethod.HttpPut,
                                        host: "appmesh.amazonaws.com", route: "/v20190125/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes/{routeName}",
                                        validator: validate_UpdateRoute_593183,
                                        base: "/", url: url_UpdateRoute_593184,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRoute_593166 = ref object of OpenApiRestCall_592364
proc url_DescribeRoute_593168(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  assert "virtualRouterName" in path,
        "`virtualRouterName` is a required path parameter"
  assert "routeName" in path, "`routeName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualRouter/"),
               (kind: VariableSegment, value: "virtualRouterName"),
               (kind: ConstantSegment, value: "/routes/"),
               (kind: VariableSegment, value: "routeName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DescribeRoute_593167(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes an existing route.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   routeName: JString (required)
  ##            : The name of the route to describe.
  ##   meshName: JString (required)
  ##           : The name of the service mesh that the route resides in.
  ##   virtualRouterName: JString (required)
  ##                    : The name of the virtual router that the route is associated with.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `routeName` field"
  var valid_593169 = path.getOrDefault("routeName")
  valid_593169 = validateParameter(valid_593169, JString, required = true,
                                 default = nil)
  if valid_593169 != nil:
    section.add "routeName", valid_593169
  var valid_593170 = path.getOrDefault("meshName")
  valid_593170 = validateParameter(valid_593170, JString, required = true,
                                 default = nil)
  if valid_593170 != nil:
    section.add "meshName", valid_593170
  var valid_593171 = path.getOrDefault("virtualRouterName")
  valid_593171 = validateParameter(valid_593171, JString, required = true,
                                 default = nil)
  if valid_593171 != nil:
    section.add "virtualRouterName", valid_593171
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593172 = header.getOrDefault("X-Amz-Signature")
  valid_593172 = validateParameter(valid_593172, JString, required = false,
                                 default = nil)
  if valid_593172 != nil:
    section.add "X-Amz-Signature", valid_593172
  var valid_593173 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593173 = validateParameter(valid_593173, JString, required = false,
                                 default = nil)
  if valid_593173 != nil:
    section.add "X-Amz-Content-Sha256", valid_593173
  var valid_593174 = header.getOrDefault("X-Amz-Date")
  valid_593174 = validateParameter(valid_593174, JString, required = false,
                                 default = nil)
  if valid_593174 != nil:
    section.add "X-Amz-Date", valid_593174
  var valid_593175 = header.getOrDefault("X-Amz-Credential")
  valid_593175 = validateParameter(valid_593175, JString, required = false,
                                 default = nil)
  if valid_593175 != nil:
    section.add "X-Amz-Credential", valid_593175
  var valid_593176 = header.getOrDefault("X-Amz-Security-Token")
  valid_593176 = validateParameter(valid_593176, JString, required = false,
                                 default = nil)
  if valid_593176 != nil:
    section.add "X-Amz-Security-Token", valid_593176
  var valid_593177 = header.getOrDefault("X-Amz-Algorithm")
  valid_593177 = validateParameter(valid_593177, JString, required = false,
                                 default = nil)
  if valid_593177 != nil:
    section.add "X-Amz-Algorithm", valid_593177
  var valid_593178 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593178 = validateParameter(valid_593178, JString, required = false,
                                 default = nil)
  if valid_593178 != nil:
    section.add "X-Amz-SignedHeaders", valid_593178
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593179: Call_DescribeRoute_593166; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an existing route.
  ## 
  let valid = call_593179.validator(path, query, header, formData, body)
  let scheme = call_593179.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593179.url(scheme.get, call_593179.host, call_593179.base,
                         call_593179.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593179, url, valid)

proc call*(call_593180: Call_DescribeRoute_593166; routeName: string;
          meshName: string; virtualRouterName: string): Recallable =
  ## describeRoute
  ## Describes an existing route.
  ##   routeName: string (required)
  ##            : The name of the route to describe.
  ##   meshName: string (required)
  ##           : The name of the service mesh that the route resides in.
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router that the route is associated with.
  var path_593181 = newJObject()
  add(path_593181, "routeName", newJString(routeName))
  add(path_593181, "meshName", newJString(meshName))
  add(path_593181, "virtualRouterName", newJString(virtualRouterName))
  result = call_593180.call(path_593181, nil, nil, nil, nil)

var describeRoute* = Call_DescribeRoute_593166(name: "describeRoute",
    meth: HttpMethod.HttpGet, host: "appmesh.amazonaws.com", route: "/v20190125/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes/{routeName}",
    validator: validate_DescribeRoute_593167, base: "/", url: url_DescribeRoute_593168,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRoute_593200 = ref object of OpenApiRestCall_592364
proc url_DeleteRoute_593202(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  assert "virtualRouterName" in path,
        "`virtualRouterName` is a required path parameter"
  assert "routeName" in path, "`routeName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualRouter/"),
               (kind: VariableSegment, value: "virtualRouterName"),
               (kind: ConstantSegment, value: "/routes/"),
               (kind: VariableSegment, value: "routeName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteRoute_593201(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes an existing route.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   routeName: JString (required)
  ##            : The name of the route to delete.
  ##   meshName: JString (required)
  ##           : The name of the service mesh to delete the route in.
  ##   virtualRouterName: JString (required)
  ##                    : The name of the virtual router to delete the route in.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `routeName` field"
  var valid_593203 = path.getOrDefault("routeName")
  valid_593203 = validateParameter(valid_593203, JString, required = true,
                                 default = nil)
  if valid_593203 != nil:
    section.add "routeName", valid_593203
  var valid_593204 = path.getOrDefault("meshName")
  valid_593204 = validateParameter(valid_593204, JString, required = true,
                                 default = nil)
  if valid_593204 != nil:
    section.add "meshName", valid_593204
  var valid_593205 = path.getOrDefault("virtualRouterName")
  valid_593205 = validateParameter(valid_593205, JString, required = true,
                                 default = nil)
  if valid_593205 != nil:
    section.add "virtualRouterName", valid_593205
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593206 = header.getOrDefault("X-Amz-Signature")
  valid_593206 = validateParameter(valid_593206, JString, required = false,
                                 default = nil)
  if valid_593206 != nil:
    section.add "X-Amz-Signature", valid_593206
  var valid_593207 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593207 = validateParameter(valid_593207, JString, required = false,
                                 default = nil)
  if valid_593207 != nil:
    section.add "X-Amz-Content-Sha256", valid_593207
  var valid_593208 = header.getOrDefault("X-Amz-Date")
  valid_593208 = validateParameter(valid_593208, JString, required = false,
                                 default = nil)
  if valid_593208 != nil:
    section.add "X-Amz-Date", valid_593208
  var valid_593209 = header.getOrDefault("X-Amz-Credential")
  valid_593209 = validateParameter(valid_593209, JString, required = false,
                                 default = nil)
  if valid_593209 != nil:
    section.add "X-Amz-Credential", valid_593209
  var valid_593210 = header.getOrDefault("X-Amz-Security-Token")
  valid_593210 = validateParameter(valid_593210, JString, required = false,
                                 default = nil)
  if valid_593210 != nil:
    section.add "X-Amz-Security-Token", valid_593210
  var valid_593211 = header.getOrDefault("X-Amz-Algorithm")
  valid_593211 = validateParameter(valid_593211, JString, required = false,
                                 default = nil)
  if valid_593211 != nil:
    section.add "X-Amz-Algorithm", valid_593211
  var valid_593212 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593212 = validateParameter(valid_593212, JString, required = false,
                                 default = nil)
  if valid_593212 != nil:
    section.add "X-Amz-SignedHeaders", valid_593212
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593213: Call_DeleteRoute_593200; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing route.
  ## 
  let valid = call_593213.validator(path, query, header, formData, body)
  let scheme = call_593213.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593213.url(scheme.get, call_593213.host, call_593213.base,
                         call_593213.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593213, url, valid)

proc call*(call_593214: Call_DeleteRoute_593200; routeName: string; meshName: string;
          virtualRouterName: string): Recallable =
  ## deleteRoute
  ## Deletes an existing route.
  ##   routeName: string (required)
  ##            : The name of the route to delete.
  ##   meshName: string (required)
  ##           : The name of the service mesh to delete the route in.
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router to delete the route in.
  var path_593215 = newJObject()
  add(path_593215, "routeName", newJString(routeName))
  add(path_593215, "meshName", newJString(meshName))
  add(path_593215, "virtualRouterName", newJString(virtualRouterName))
  result = call_593214.call(path_593215, nil, nil, nil, nil)

var deleteRoute* = Call_DeleteRoute_593200(name: "deleteRoute",
                                        meth: HttpMethod.HttpDelete,
                                        host: "appmesh.amazonaws.com", route: "/v20190125/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes/{routeName}",
                                        validator: validate_DeleteRoute_593201,
                                        base: "/", url: url_DeleteRoute_593202,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVirtualNode_593231 = ref object of OpenApiRestCall_592364
proc url_UpdateVirtualNode_593233(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  assert "virtualNodeName" in path, "`virtualNodeName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualNodes/"),
               (kind: VariableSegment, value: "virtualNodeName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UpdateVirtualNode_593232(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Updates an existing virtual node in a specified service mesh.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh that the virtual node resides in.
  ##   virtualNodeName: JString (required)
  ##                  : The name of the virtual node to update.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_593234 = path.getOrDefault("meshName")
  valid_593234 = validateParameter(valid_593234, JString, required = true,
                                 default = nil)
  if valid_593234 != nil:
    section.add "meshName", valid_593234
  var valid_593235 = path.getOrDefault("virtualNodeName")
  valid_593235 = validateParameter(valid_593235, JString, required = true,
                                 default = nil)
  if valid_593235 != nil:
    section.add "virtualNodeName", valid_593235
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593236 = header.getOrDefault("X-Amz-Signature")
  valid_593236 = validateParameter(valid_593236, JString, required = false,
                                 default = nil)
  if valid_593236 != nil:
    section.add "X-Amz-Signature", valid_593236
  var valid_593237 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593237 = validateParameter(valid_593237, JString, required = false,
                                 default = nil)
  if valid_593237 != nil:
    section.add "X-Amz-Content-Sha256", valid_593237
  var valid_593238 = header.getOrDefault("X-Amz-Date")
  valid_593238 = validateParameter(valid_593238, JString, required = false,
                                 default = nil)
  if valid_593238 != nil:
    section.add "X-Amz-Date", valid_593238
  var valid_593239 = header.getOrDefault("X-Amz-Credential")
  valid_593239 = validateParameter(valid_593239, JString, required = false,
                                 default = nil)
  if valid_593239 != nil:
    section.add "X-Amz-Credential", valid_593239
  var valid_593240 = header.getOrDefault("X-Amz-Security-Token")
  valid_593240 = validateParameter(valid_593240, JString, required = false,
                                 default = nil)
  if valid_593240 != nil:
    section.add "X-Amz-Security-Token", valid_593240
  var valid_593241 = header.getOrDefault("X-Amz-Algorithm")
  valid_593241 = validateParameter(valid_593241, JString, required = false,
                                 default = nil)
  if valid_593241 != nil:
    section.add "X-Amz-Algorithm", valid_593241
  var valid_593242 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593242 = validateParameter(valid_593242, JString, required = false,
                                 default = nil)
  if valid_593242 != nil:
    section.add "X-Amz-SignedHeaders", valid_593242
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593244: Call_UpdateVirtualNode_593231; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing virtual node in a specified service mesh.
  ## 
  let valid = call_593244.validator(path, query, header, formData, body)
  let scheme = call_593244.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593244.url(scheme.get, call_593244.host, call_593244.base,
                         call_593244.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593244, url, valid)

proc call*(call_593245: Call_UpdateVirtualNode_593231; meshName: string;
          body: JsonNode; virtualNodeName: string): Recallable =
  ## updateVirtualNode
  ## Updates an existing virtual node in a specified service mesh.
  ##   meshName: string (required)
  ##           : The name of the service mesh that the virtual node resides in.
  ##   body: JObject (required)
  ##   virtualNodeName: string (required)
  ##                  : The name of the virtual node to update.
  var path_593246 = newJObject()
  var body_593247 = newJObject()
  add(path_593246, "meshName", newJString(meshName))
  if body != nil:
    body_593247 = body
  add(path_593246, "virtualNodeName", newJString(virtualNodeName))
  result = call_593245.call(path_593246, nil, nil, nil, body_593247)

var updateVirtualNode* = Call_UpdateVirtualNode_593231(name: "updateVirtualNode",
    meth: HttpMethod.HttpPut, host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualNodes/{virtualNodeName}",
    validator: validate_UpdateVirtualNode_593232, base: "/",
    url: url_UpdateVirtualNode_593233, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeVirtualNode_593216 = ref object of OpenApiRestCall_592364
proc url_DescribeVirtualNode_593218(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  assert "virtualNodeName" in path, "`virtualNodeName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualNodes/"),
               (kind: VariableSegment, value: "virtualNodeName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DescribeVirtualNode_593217(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Describes an existing virtual node.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh that the virtual node resides in.
  ##   virtualNodeName: JString (required)
  ##                  : The name of the virtual node to describe.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_593219 = path.getOrDefault("meshName")
  valid_593219 = validateParameter(valid_593219, JString, required = true,
                                 default = nil)
  if valid_593219 != nil:
    section.add "meshName", valid_593219
  var valid_593220 = path.getOrDefault("virtualNodeName")
  valid_593220 = validateParameter(valid_593220, JString, required = true,
                                 default = nil)
  if valid_593220 != nil:
    section.add "virtualNodeName", valid_593220
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593221 = header.getOrDefault("X-Amz-Signature")
  valid_593221 = validateParameter(valid_593221, JString, required = false,
                                 default = nil)
  if valid_593221 != nil:
    section.add "X-Amz-Signature", valid_593221
  var valid_593222 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593222 = validateParameter(valid_593222, JString, required = false,
                                 default = nil)
  if valid_593222 != nil:
    section.add "X-Amz-Content-Sha256", valid_593222
  var valid_593223 = header.getOrDefault("X-Amz-Date")
  valid_593223 = validateParameter(valid_593223, JString, required = false,
                                 default = nil)
  if valid_593223 != nil:
    section.add "X-Amz-Date", valid_593223
  var valid_593224 = header.getOrDefault("X-Amz-Credential")
  valid_593224 = validateParameter(valid_593224, JString, required = false,
                                 default = nil)
  if valid_593224 != nil:
    section.add "X-Amz-Credential", valid_593224
  var valid_593225 = header.getOrDefault("X-Amz-Security-Token")
  valid_593225 = validateParameter(valid_593225, JString, required = false,
                                 default = nil)
  if valid_593225 != nil:
    section.add "X-Amz-Security-Token", valid_593225
  var valid_593226 = header.getOrDefault("X-Amz-Algorithm")
  valid_593226 = validateParameter(valid_593226, JString, required = false,
                                 default = nil)
  if valid_593226 != nil:
    section.add "X-Amz-Algorithm", valid_593226
  var valid_593227 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593227 = validateParameter(valid_593227, JString, required = false,
                                 default = nil)
  if valid_593227 != nil:
    section.add "X-Amz-SignedHeaders", valid_593227
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593228: Call_DescribeVirtualNode_593216; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an existing virtual node.
  ## 
  let valid = call_593228.validator(path, query, header, formData, body)
  let scheme = call_593228.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593228.url(scheme.get, call_593228.host, call_593228.base,
                         call_593228.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593228, url, valid)

proc call*(call_593229: Call_DescribeVirtualNode_593216; meshName: string;
          virtualNodeName: string): Recallable =
  ## describeVirtualNode
  ## Describes an existing virtual node.
  ##   meshName: string (required)
  ##           : The name of the service mesh that the virtual node resides in.
  ##   virtualNodeName: string (required)
  ##                  : The name of the virtual node to describe.
  var path_593230 = newJObject()
  add(path_593230, "meshName", newJString(meshName))
  add(path_593230, "virtualNodeName", newJString(virtualNodeName))
  result = call_593229.call(path_593230, nil, nil, nil, nil)

var describeVirtualNode* = Call_DescribeVirtualNode_593216(
    name: "describeVirtualNode", meth: HttpMethod.HttpGet,
    host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualNodes/{virtualNodeName}",
    validator: validate_DescribeVirtualNode_593217, base: "/",
    url: url_DescribeVirtualNode_593218, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVirtualNode_593248 = ref object of OpenApiRestCall_592364
proc url_DeleteVirtualNode_593250(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  assert "virtualNodeName" in path, "`virtualNodeName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualNodes/"),
               (kind: VariableSegment, value: "virtualNodeName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteVirtualNode_593249(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Deletes an existing virtual node.</p>
  ##          <p>You must delete any virtual services that list a virtual node as a service provider
  ##          before you can delete the virtual node itself.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh to delete the virtual node in.
  ##   virtualNodeName: JString (required)
  ##                  : The name of the virtual node to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_593251 = path.getOrDefault("meshName")
  valid_593251 = validateParameter(valid_593251, JString, required = true,
                                 default = nil)
  if valid_593251 != nil:
    section.add "meshName", valid_593251
  var valid_593252 = path.getOrDefault("virtualNodeName")
  valid_593252 = validateParameter(valid_593252, JString, required = true,
                                 default = nil)
  if valid_593252 != nil:
    section.add "virtualNodeName", valid_593252
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593253 = header.getOrDefault("X-Amz-Signature")
  valid_593253 = validateParameter(valid_593253, JString, required = false,
                                 default = nil)
  if valid_593253 != nil:
    section.add "X-Amz-Signature", valid_593253
  var valid_593254 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593254 = validateParameter(valid_593254, JString, required = false,
                                 default = nil)
  if valid_593254 != nil:
    section.add "X-Amz-Content-Sha256", valid_593254
  var valid_593255 = header.getOrDefault("X-Amz-Date")
  valid_593255 = validateParameter(valid_593255, JString, required = false,
                                 default = nil)
  if valid_593255 != nil:
    section.add "X-Amz-Date", valid_593255
  var valid_593256 = header.getOrDefault("X-Amz-Credential")
  valid_593256 = validateParameter(valid_593256, JString, required = false,
                                 default = nil)
  if valid_593256 != nil:
    section.add "X-Amz-Credential", valid_593256
  var valid_593257 = header.getOrDefault("X-Amz-Security-Token")
  valid_593257 = validateParameter(valid_593257, JString, required = false,
                                 default = nil)
  if valid_593257 != nil:
    section.add "X-Amz-Security-Token", valid_593257
  var valid_593258 = header.getOrDefault("X-Amz-Algorithm")
  valid_593258 = validateParameter(valid_593258, JString, required = false,
                                 default = nil)
  if valid_593258 != nil:
    section.add "X-Amz-Algorithm", valid_593258
  var valid_593259 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593259 = validateParameter(valid_593259, JString, required = false,
                                 default = nil)
  if valid_593259 != nil:
    section.add "X-Amz-SignedHeaders", valid_593259
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593260: Call_DeleteVirtualNode_593248; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an existing virtual node.</p>
  ##          <p>You must delete any virtual services that list a virtual node as a service provider
  ##          before you can delete the virtual node itself.</p>
  ## 
  let valid = call_593260.validator(path, query, header, formData, body)
  let scheme = call_593260.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593260.url(scheme.get, call_593260.host, call_593260.base,
                         call_593260.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593260, url, valid)

proc call*(call_593261: Call_DeleteVirtualNode_593248; meshName: string;
          virtualNodeName: string): Recallable =
  ## deleteVirtualNode
  ## <p>Deletes an existing virtual node.</p>
  ##          <p>You must delete any virtual services that list a virtual node as a service provider
  ##          before you can delete the virtual node itself.</p>
  ##   meshName: string (required)
  ##           : The name of the service mesh to delete the virtual node in.
  ##   virtualNodeName: string (required)
  ##                  : The name of the virtual node to delete.
  var path_593262 = newJObject()
  add(path_593262, "meshName", newJString(meshName))
  add(path_593262, "virtualNodeName", newJString(virtualNodeName))
  result = call_593261.call(path_593262, nil, nil, nil, nil)

var deleteVirtualNode* = Call_DeleteVirtualNode_593248(name: "deleteVirtualNode",
    meth: HttpMethod.HttpDelete, host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualNodes/{virtualNodeName}",
    validator: validate_DeleteVirtualNode_593249, base: "/",
    url: url_DeleteVirtualNode_593250, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVirtualRouter_593278 = ref object of OpenApiRestCall_592364
proc url_UpdateVirtualRouter_593280(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  assert "virtualRouterName" in path,
        "`virtualRouterName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualRouters/"),
               (kind: VariableSegment, value: "virtualRouterName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UpdateVirtualRouter_593279(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Updates an existing virtual router in a specified service mesh.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh that the virtual router resides in.
  ##   virtualRouterName: JString (required)
  ##                    : The name of the virtual router to update.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_593281 = path.getOrDefault("meshName")
  valid_593281 = validateParameter(valid_593281, JString, required = true,
                                 default = nil)
  if valid_593281 != nil:
    section.add "meshName", valid_593281
  var valid_593282 = path.getOrDefault("virtualRouterName")
  valid_593282 = validateParameter(valid_593282, JString, required = true,
                                 default = nil)
  if valid_593282 != nil:
    section.add "virtualRouterName", valid_593282
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593283 = header.getOrDefault("X-Amz-Signature")
  valid_593283 = validateParameter(valid_593283, JString, required = false,
                                 default = nil)
  if valid_593283 != nil:
    section.add "X-Amz-Signature", valid_593283
  var valid_593284 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593284 = validateParameter(valid_593284, JString, required = false,
                                 default = nil)
  if valid_593284 != nil:
    section.add "X-Amz-Content-Sha256", valid_593284
  var valid_593285 = header.getOrDefault("X-Amz-Date")
  valid_593285 = validateParameter(valid_593285, JString, required = false,
                                 default = nil)
  if valid_593285 != nil:
    section.add "X-Amz-Date", valid_593285
  var valid_593286 = header.getOrDefault("X-Amz-Credential")
  valid_593286 = validateParameter(valid_593286, JString, required = false,
                                 default = nil)
  if valid_593286 != nil:
    section.add "X-Amz-Credential", valid_593286
  var valid_593287 = header.getOrDefault("X-Amz-Security-Token")
  valid_593287 = validateParameter(valid_593287, JString, required = false,
                                 default = nil)
  if valid_593287 != nil:
    section.add "X-Amz-Security-Token", valid_593287
  var valid_593288 = header.getOrDefault("X-Amz-Algorithm")
  valid_593288 = validateParameter(valid_593288, JString, required = false,
                                 default = nil)
  if valid_593288 != nil:
    section.add "X-Amz-Algorithm", valid_593288
  var valid_593289 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593289 = validateParameter(valid_593289, JString, required = false,
                                 default = nil)
  if valid_593289 != nil:
    section.add "X-Amz-SignedHeaders", valid_593289
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593291: Call_UpdateVirtualRouter_593278; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing virtual router in a specified service mesh.
  ## 
  let valid = call_593291.validator(path, query, header, formData, body)
  let scheme = call_593291.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593291.url(scheme.get, call_593291.host, call_593291.base,
                         call_593291.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593291, url, valid)

proc call*(call_593292: Call_UpdateVirtualRouter_593278; meshName: string;
          body: JsonNode; virtualRouterName: string): Recallable =
  ## updateVirtualRouter
  ## Updates an existing virtual router in a specified service mesh.
  ##   meshName: string (required)
  ##           : The name of the service mesh that the virtual router resides in.
  ##   body: JObject (required)
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router to update.
  var path_593293 = newJObject()
  var body_593294 = newJObject()
  add(path_593293, "meshName", newJString(meshName))
  if body != nil:
    body_593294 = body
  add(path_593293, "virtualRouterName", newJString(virtualRouterName))
  result = call_593292.call(path_593293, nil, nil, nil, body_593294)

var updateVirtualRouter* = Call_UpdateVirtualRouter_593278(
    name: "updateVirtualRouter", meth: HttpMethod.HttpPut,
    host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualRouters/{virtualRouterName}",
    validator: validate_UpdateVirtualRouter_593279, base: "/",
    url: url_UpdateVirtualRouter_593280, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeVirtualRouter_593263 = ref object of OpenApiRestCall_592364
proc url_DescribeVirtualRouter_593265(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  assert "virtualRouterName" in path,
        "`virtualRouterName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualRouters/"),
               (kind: VariableSegment, value: "virtualRouterName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DescribeVirtualRouter_593264(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes an existing virtual router.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh that the virtual router resides in.
  ##   virtualRouterName: JString (required)
  ##                    : The name of the virtual router to describe.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_593266 = path.getOrDefault("meshName")
  valid_593266 = validateParameter(valid_593266, JString, required = true,
                                 default = nil)
  if valid_593266 != nil:
    section.add "meshName", valid_593266
  var valid_593267 = path.getOrDefault("virtualRouterName")
  valid_593267 = validateParameter(valid_593267, JString, required = true,
                                 default = nil)
  if valid_593267 != nil:
    section.add "virtualRouterName", valid_593267
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593268 = header.getOrDefault("X-Amz-Signature")
  valid_593268 = validateParameter(valid_593268, JString, required = false,
                                 default = nil)
  if valid_593268 != nil:
    section.add "X-Amz-Signature", valid_593268
  var valid_593269 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593269 = validateParameter(valid_593269, JString, required = false,
                                 default = nil)
  if valid_593269 != nil:
    section.add "X-Amz-Content-Sha256", valid_593269
  var valid_593270 = header.getOrDefault("X-Amz-Date")
  valid_593270 = validateParameter(valid_593270, JString, required = false,
                                 default = nil)
  if valid_593270 != nil:
    section.add "X-Amz-Date", valid_593270
  var valid_593271 = header.getOrDefault("X-Amz-Credential")
  valid_593271 = validateParameter(valid_593271, JString, required = false,
                                 default = nil)
  if valid_593271 != nil:
    section.add "X-Amz-Credential", valid_593271
  var valid_593272 = header.getOrDefault("X-Amz-Security-Token")
  valid_593272 = validateParameter(valid_593272, JString, required = false,
                                 default = nil)
  if valid_593272 != nil:
    section.add "X-Amz-Security-Token", valid_593272
  var valid_593273 = header.getOrDefault("X-Amz-Algorithm")
  valid_593273 = validateParameter(valid_593273, JString, required = false,
                                 default = nil)
  if valid_593273 != nil:
    section.add "X-Amz-Algorithm", valid_593273
  var valid_593274 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593274 = validateParameter(valid_593274, JString, required = false,
                                 default = nil)
  if valid_593274 != nil:
    section.add "X-Amz-SignedHeaders", valid_593274
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593275: Call_DescribeVirtualRouter_593263; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an existing virtual router.
  ## 
  let valid = call_593275.validator(path, query, header, formData, body)
  let scheme = call_593275.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593275.url(scheme.get, call_593275.host, call_593275.base,
                         call_593275.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593275, url, valid)

proc call*(call_593276: Call_DescribeVirtualRouter_593263; meshName: string;
          virtualRouterName: string): Recallable =
  ## describeVirtualRouter
  ## Describes an existing virtual router.
  ##   meshName: string (required)
  ##           : The name of the service mesh that the virtual router resides in.
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router to describe.
  var path_593277 = newJObject()
  add(path_593277, "meshName", newJString(meshName))
  add(path_593277, "virtualRouterName", newJString(virtualRouterName))
  result = call_593276.call(path_593277, nil, nil, nil, nil)

var describeVirtualRouter* = Call_DescribeVirtualRouter_593263(
    name: "describeVirtualRouter", meth: HttpMethod.HttpGet,
    host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualRouters/{virtualRouterName}",
    validator: validate_DescribeVirtualRouter_593264, base: "/",
    url: url_DescribeVirtualRouter_593265, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVirtualRouter_593295 = ref object of OpenApiRestCall_592364
proc url_DeleteVirtualRouter_593297(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  assert "virtualRouterName" in path,
        "`virtualRouterName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualRouters/"),
               (kind: VariableSegment, value: "virtualRouterName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteVirtualRouter_593296(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Deletes an existing virtual router.</p>
  ##          <p>You must delete any routes associated with the virtual router before you can delete the
  ##          router itself.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh to delete the virtual router in.
  ##   virtualRouterName: JString (required)
  ##                    : The name of the virtual router to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_593298 = path.getOrDefault("meshName")
  valid_593298 = validateParameter(valid_593298, JString, required = true,
                                 default = nil)
  if valid_593298 != nil:
    section.add "meshName", valid_593298
  var valid_593299 = path.getOrDefault("virtualRouterName")
  valid_593299 = validateParameter(valid_593299, JString, required = true,
                                 default = nil)
  if valid_593299 != nil:
    section.add "virtualRouterName", valid_593299
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593300 = header.getOrDefault("X-Amz-Signature")
  valid_593300 = validateParameter(valid_593300, JString, required = false,
                                 default = nil)
  if valid_593300 != nil:
    section.add "X-Amz-Signature", valid_593300
  var valid_593301 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593301 = validateParameter(valid_593301, JString, required = false,
                                 default = nil)
  if valid_593301 != nil:
    section.add "X-Amz-Content-Sha256", valid_593301
  var valid_593302 = header.getOrDefault("X-Amz-Date")
  valid_593302 = validateParameter(valid_593302, JString, required = false,
                                 default = nil)
  if valid_593302 != nil:
    section.add "X-Amz-Date", valid_593302
  var valid_593303 = header.getOrDefault("X-Amz-Credential")
  valid_593303 = validateParameter(valid_593303, JString, required = false,
                                 default = nil)
  if valid_593303 != nil:
    section.add "X-Amz-Credential", valid_593303
  var valid_593304 = header.getOrDefault("X-Amz-Security-Token")
  valid_593304 = validateParameter(valid_593304, JString, required = false,
                                 default = nil)
  if valid_593304 != nil:
    section.add "X-Amz-Security-Token", valid_593304
  var valid_593305 = header.getOrDefault("X-Amz-Algorithm")
  valid_593305 = validateParameter(valid_593305, JString, required = false,
                                 default = nil)
  if valid_593305 != nil:
    section.add "X-Amz-Algorithm", valid_593305
  var valid_593306 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593306 = validateParameter(valid_593306, JString, required = false,
                                 default = nil)
  if valid_593306 != nil:
    section.add "X-Amz-SignedHeaders", valid_593306
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593307: Call_DeleteVirtualRouter_593295; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an existing virtual router.</p>
  ##          <p>You must delete any routes associated with the virtual router before you can delete the
  ##          router itself.</p>
  ## 
  let valid = call_593307.validator(path, query, header, formData, body)
  let scheme = call_593307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593307.url(scheme.get, call_593307.host, call_593307.base,
                         call_593307.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593307, url, valid)

proc call*(call_593308: Call_DeleteVirtualRouter_593295; meshName: string;
          virtualRouterName: string): Recallable =
  ## deleteVirtualRouter
  ## <p>Deletes an existing virtual router.</p>
  ##          <p>You must delete any routes associated with the virtual router before you can delete the
  ##          router itself.</p>
  ##   meshName: string (required)
  ##           : The name of the service mesh to delete the virtual router in.
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router to delete.
  var path_593309 = newJObject()
  add(path_593309, "meshName", newJString(meshName))
  add(path_593309, "virtualRouterName", newJString(virtualRouterName))
  result = call_593308.call(path_593309, nil, nil, nil, nil)

var deleteVirtualRouter* = Call_DeleteVirtualRouter_593295(
    name: "deleteVirtualRouter", meth: HttpMethod.HttpDelete,
    host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualRouters/{virtualRouterName}",
    validator: validate_DeleteVirtualRouter_593296, base: "/",
    url: url_DeleteVirtualRouter_593297, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVirtualService_593325 = ref object of OpenApiRestCall_592364
proc url_UpdateVirtualService_593327(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  assert "virtualServiceName" in path,
        "`virtualServiceName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualServices/"),
               (kind: VariableSegment, value: "virtualServiceName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UpdateVirtualService_593326(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates an existing virtual service in a specified service mesh.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   virtualServiceName: JString (required)
  ##                     : The name of the virtual service to update.
  ##   meshName: JString (required)
  ##           : The name of the service mesh that the virtual service resides in.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `virtualServiceName` field"
  var valid_593328 = path.getOrDefault("virtualServiceName")
  valid_593328 = validateParameter(valid_593328, JString, required = true,
                                 default = nil)
  if valid_593328 != nil:
    section.add "virtualServiceName", valid_593328
  var valid_593329 = path.getOrDefault("meshName")
  valid_593329 = validateParameter(valid_593329, JString, required = true,
                                 default = nil)
  if valid_593329 != nil:
    section.add "meshName", valid_593329
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593330 = header.getOrDefault("X-Amz-Signature")
  valid_593330 = validateParameter(valid_593330, JString, required = false,
                                 default = nil)
  if valid_593330 != nil:
    section.add "X-Amz-Signature", valid_593330
  var valid_593331 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593331 = validateParameter(valid_593331, JString, required = false,
                                 default = nil)
  if valid_593331 != nil:
    section.add "X-Amz-Content-Sha256", valid_593331
  var valid_593332 = header.getOrDefault("X-Amz-Date")
  valid_593332 = validateParameter(valid_593332, JString, required = false,
                                 default = nil)
  if valid_593332 != nil:
    section.add "X-Amz-Date", valid_593332
  var valid_593333 = header.getOrDefault("X-Amz-Credential")
  valid_593333 = validateParameter(valid_593333, JString, required = false,
                                 default = nil)
  if valid_593333 != nil:
    section.add "X-Amz-Credential", valid_593333
  var valid_593334 = header.getOrDefault("X-Amz-Security-Token")
  valid_593334 = validateParameter(valid_593334, JString, required = false,
                                 default = nil)
  if valid_593334 != nil:
    section.add "X-Amz-Security-Token", valid_593334
  var valid_593335 = header.getOrDefault("X-Amz-Algorithm")
  valid_593335 = validateParameter(valid_593335, JString, required = false,
                                 default = nil)
  if valid_593335 != nil:
    section.add "X-Amz-Algorithm", valid_593335
  var valid_593336 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593336 = validateParameter(valid_593336, JString, required = false,
                                 default = nil)
  if valid_593336 != nil:
    section.add "X-Amz-SignedHeaders", valid_593336
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593338: Call_UpdateVirtualService_593325; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing virtual service in a specified service mesh.
  ## 
  let valid = call_593338.validator(path, query, header, formData, body)
  let scheme = call_593338.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593338.url(scheme.get, call_593338.host, call_593338.base,
                         call_593338.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593338, url, valid)

proc call*(call_593339: Call_UpdateVirtualService_593325;
          virtualServiceName: string; meshName: string; body: JsonNode): Recallable =
  ## updateVirtualService
  ## Updates an existing virtual service in a specified service mesh.
  ##   virtualServiceName: string (required)
  ##                     : The name of the virtual service to update.
  ##   meshName: string (required)
  ##           : The name of the service mesh that the virtual service resides in.
  ##   body: JObject (required)
  var path_593340 = newJObject()
  var body_593341 = newJObject()
  add(path_593340, "virtualServiceName", newJString(virtualServiceName))
  add(path_593340, "meshName", newJString(meshName))
  if body != nil:
    body_593341 = body
  result = call_593339.call(path_593340, nil, nil, nil, body_593341)

var updateVirtualService* = Call_UpdateVirtualService_593325(
    name: "updateVirtualService", meth: HttpMethod.HttpPut,
    host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualServices/{virtualServiceName}",
    validator: validate_UpdateVirtualService_593326, base: "/",
    url: url_UpdateVirtualService_593327, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeVirtualService_593310 = ref object of OpenApiRestCall_592364
proc url_DescribeVirtualService_593312(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  assert "virtualServiceName" in path,
        "`virtualServiceName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualServices/"),
               (kind: VariableSegment, value: "virtualServiceName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DescribeVirtualService_593311(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes an existing virtual service.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   virtualServiceName: JString (required)
  ##                     : The name of the virtual service to describe.
  ##   meshName: JString (required)
  ##           : The name of the service mesh that the virtual service resides in.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `virtualServiceName` field"
  var valid_593313 = path.getOrDefault("virtualServiceName")
  valid_593313 = validateParameter(valid_593313, JString, required = true,
                                 default = nil)
  if valid_593313 != nil:
    section.add "virtualServiceName", valid_593313
  var valid_593314 = path.getOrDefault("meshName")
  valid_593314 = validateParameter(valid_593314, JString, required = true,
                                 default = nil)
  if valid_593314 != nil:
    section.add "meshName", valid_593314
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593315 = header.getOrDefault("X-Amz-Signature")
  valid_593315 = validateParameter(valid_593315, JString, required = false,
                                 default = nil)
  if valid_593315 != nil:
    section.add "X-Amz-Signature", valid_593315
  var valid_593316 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593316 = validateParameter(valid_593316, JString, required = false,
                                 default = nil)
  if valid_593316 != nil:
    section.add "X-Amz-Content-Sha256", valid_593316
  var valid_593317 = header.getOrDefault("X-Amz-Date")
  valid_593317 = validateParameter(valid_593317, JString, required = false,
                                 default = nil)
  if valid_593317 != nil:
    section.add "X-Amz-Date", valid_593317
  var valid_593318 = header.getOrDefault("X-Amz-Credential")
  valid_593318 = validateParameter(valid_593318, JString, required = false,
                                 default = nil)
  if valid_593318 != nil:
    section.add "X-Amz-Credential", valid_593318
  var valid_593319 = header.getOrDefault("X-Amz-Security-Token")
  valid_593319 = validateParameter(valid_593319, JString, required = false,
                                 default = nil)
  if valid_593319 != nil:
    section.add "X-Amz-Security-Token", valid_593319
  var valid_593320 = header.getOrDefault("X-Amz-Algorithm")
  valid_593320 = validateParameter(valid_593320, JString, required = false,
                                 default = nil)
  if valid_593320 != nil:
    section.add "X-Amz-Algorithm", valid_593320
  var valid_593321 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593321 = validateParameter(valid_593321, JString, required = false,
                                 default = nil)
  if valid_593321 != nil:
    section.add "X-Amz-SignedHeaders", valid_593321
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593322: Call_DescribeVirtualService_593310; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an existing virtual service.
  ## 
  let valid = call_593322.validator(path, query, header, formData, body)
  let scheme = call_593322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593322.url(scheme.get, call_593322.host, call_593322.base,
                         call_593322.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593322, url, valid)

proc call*(call_593323: Call_DescribeVirtualService_593310;
          virtualServiceName: string; meshName: string): Recallable =
  ## describeVirtualService
  ## Describes an existing virtual service.
  ##   virtualServiceName: string (required)
  ##                     : The name of the virtual service to describe.
  ##   meshName: string (required)
  ##           : The name of the service mesh that the virtual service resides in.
  var path_593324 = newJObject()
  add(path_593324, "virtualServiceName", newJString(virtualServiceName))
  add(path_593324, "meshName", newJString(meshName))
  result = call_593323.call(path_593324, nil, nil, nil, nil)

var describeVirtualService* = Call_DescribeVirtualService_593310(
    name: "describeVirtualService", meth: HttpMethod.HttpGet,
    host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualServices/{virtualServiceName}",
    validator: validate_DescribeVirtualService_593311, base: "/",
    url: url_DescribeVirtualService_593312, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVirtualService_593342 = ref object of OpenApiRestCall_592364
proc url_DeleteVirtualService_593344(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  assert "virtualServiceName" in path,
        "`virtualServiceName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualServices/"),
               (kind: VariableSegment, value: "virtualServiceName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteVirtualService_593343(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes an existing virtual service.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   virtualServiceName: JString (required)
  ##                     : The name of the virtual service to delete.
  ##   meshName: JString (required)
  ##           : The name of the service mesh to delete the virtual service in.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `virtualServiceName` field"
  var valid_593345 = path.getOrDefault("virtualServiceName")
  valid_593345 = validateParameter(valid_593345, JString, required = true,
                                 default = nil)
  if valid_593345 != nil:
    section.add "virtualServiceName", valid_593345
  var valid_593346 = path.getOrDefault("meshName")
  valid_593346 = validateParameter(valid_593346, JString, required = true,
                                 default = nil)
  if valid_593346 != nil:
    section.add "meshName", valid_593346
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593347 = header.getOrDefault("X-Amz-Signature")
  valid_593347 = validateParameter(valid_593347, JString, required = false,
                                 default = nil)
  if valid_593347 != nil:
    section.add "X-Amz-Signature", valid_593347
  var valid_593348 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593348 = validateParameter(valid_593348, JString, required = false,
                                 default = nil)
  if valid_593348 != nil:
    section.add "X-Amz-Content-Sha256", valid_593348
  var valid_593349 = header.getOrDefault("X-Amz-Date")
  valid_593349 = validateParameter(valid_593349, JString, required = false,
                                 default = nil)
  if valid_593349 != nil:
    section.add "X-Amz-Date", valid_593349
  var valid_593350 = header.getOrDefault("X-Amz-Credential")
  valid_593350 = validateParameter(valid_593350, JString, required = false,
                                 default = nil)
  if valid_593350 != nil:
    section.add "X-Amz-Credential", valid_593350
  var valid_593351 = header.getOrDefault("X-Amz-Security-Token")
  valid_593351 = validateParameter(valid_593351, JString, required = false,
                                 default = nil)
  if valid_593351 != nil:
    section.add "X-Amz-Security-Token", valid_593351
  var valid_593352 = header.getOrDefault("X-Amz-Algorithm")
  valid_593352 = validateParameter(valid_593352, JString, required = false,
                                 default = nil)
  if valid_593352 != nil:
    section.add "X-Amz-Algorithm", valid_593352
  var valid_593353 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593353 = validateParameter(valid_593353, JString, required = false,
                                 default = nil)
  if valid_593353 != nil:
    section.add "X-Amz-SignedHeaders", valid_593353
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593354: Call_DeleteVirtualService_593342; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing virtual service.
  ## 
  let valid = call_593354.validator(path, query, header, formData, body)
  let scheme = call_593354.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593354.url(scheme.get, call_593354.host, call_593354.base,
                         call_593354.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593354, url, valid)

proc call*(call_593355: Call_DeleteVirtualService_593342;
          virtualServiceName: string; meshName: string): Recallable =
  ## deleteVirtualService
  ## Deletes an existing virtual service.
  ##   virtualServiceName: string (required)
  ##                     : The name of the virtual service to delete.
  ##   meshName: string (required)
  ##           : The name of the service mesh to delete the virtual service in.
  var path_593356 = newJObject()
  add(path_593356, "virtualServiceName", newJString(virtualServiceName))
  add(path_593356, "meshName", newJString(meshName))
  result = call_593355.call(path_593356, nil, nil, nil, nil)

var deleteVirtualService* = Call_DeleteVirtualService_593342(
    name: "deleteVirtualService", meth: HttpMethod.HttpDelete,
    host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualServices/{virtualServiceName}",
    validator: validate_DeleteVirtualService_593343, base: "/",
    url: url_DeleteVirtualService_593344, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_593357 = ref object of OpenApiRestCall_592364
proc url_ListTagsForResource_593359(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTagsForResource_593358(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## List the tags for an App Mesh resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The <code>nextToken</code> value returned from a previous paginated
  ##             <code>ListTagsForResource</code> request where <code>limit</code> was used and the
  ##          results exceeded the value of that parameter. Pagination continues from the end of the
  ##          previous results that returned the <code>nextToken</code> value.
  ##   limit: JInt
  ##        : The maximum number of tag results returned by <code>ListTagsForResource</code> in
  ##          paginated output. When this parameter is used, <code>ListTagsForResource</code> returns
  ##          only <code>limit</code> results in a single page along with a <code>nextToken</code>
  ##          response element. You can see the remaining results of the initial request by sending
  ##          another <code>ListTagsForResource</code> request with the returned <code>nextToken</code>
  ##          value. This value can be between 1 and 100. If you don't use
  ##          this parameter, <code>ListTagsForResource</code> returns up to 100
  ##          results and a <code>nextToken</code> value if applicable.
  ##   resourceArn: JString (required)
  ##              : The Amazon Resource Name (ARN) that identifies the resource to list the tags for.
  section = newJObject()
  var valid_593360 = query.getOrDefault("nextToken")
  valid_593360 = validateParameter(valid_593360, JString, required = false,
                                 default = nil)
  if valid_593360 != nil:
    section.add "nextToken", valid_593360
  var valid_593361 = query.getOrDefault("limit")
  valid_593361 = validateParameter(valid_593361, JInt, required = false, default = nil)
  if valid_593361 != nil:
    section.add "limit", valid_593361
  assert query != nil,
        "query argument is necessary due to required `resourceArn` field"
  var valid_593362 = query.getOrDefault("resourceArn")
  valid_593362 = validateParameter(valid_593362, JString, required = true,
                                 default = nil)
  if valid_593362 != nil:
    section.add "resourceArn", valid_593362
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593363 = header.getOrDefault("X-Amz-Signature")
  valid_593363 = validateParameter(valid_593363, JString, required = false,
                                 default = nil)
  if valid_593363 != nil:
    section.add "X-Amz-Signature", valid_593363
  var valid_593364 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593364 = validateParameter(valid_593364, JString, required = false,
                                 default = nil)
  if valid_593364 != nil:
    section.add "X-Amz-Content-Sha256", valid_593364
  var valid_593365 = header.getOrDefault("X-Amz-Date")
  valid_593365 = validateParameter(valid_593365, JString, required = false,
                                 default = nil)
  if valid_593365 != nil:
    section.add "X-Amz-Date", valid_593365
  var valid_593366 = header.getOrDefault("X-Amz-Credential")
  valid_593366 = validateParameter(valid_593366, JString, required = false,
                                 default = nil)
  if valid_593366 != nil:
    section.add "X-Amz-Credential", valid_593366
  var valid_593367 = header.getOrDefault("X-Amz-Security-Token")
  valid_593367 = validateParameter(valid_593367, JString, required = false,
                                 default = nil)
  if valid_593367 != nil:
    section.add "X-Amz-Security-Token", valid_593367
  var valid_593368 = header.getOrDefault("X-Amz-Algorithm")
  valid_593368 = validateParameter(valid_593368, JString, required = false,
                                 default = nil)
  if valid_593368 != nil:
    section.add "X-Amz-Algorithm", valid_593368
  var valid_593369 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593369 = validateParameter(valid_593369, JString, required = false,
                                 default = nil)
  if valid_593369 != nil:
    section.add "X-Amz-SignedHeaders", valid_593369
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593370: Call_ListTagsForResource_593357; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the tags for an App Mesh resource.
  ## 
  let valid = call_593370.validator(path, query, header, formData, body)
  let scheme = call_593370.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593370.url(scheme.get, call_593370.host, call_593370.base,
                         call_593370.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593370, url, valid)

proc call*(call_593371: Call_ListTagsForResource_593357; resourceArn: string;
          nextToken: string = ""; limit: int = 0): Recallable =
  ## listTagsForResource
  ## List the tags for an App Mesh resource.
  ##   nextToken: string
  ##            : The <code>nextToken</code> value returned from a previous paginated
  ##             <code>ListTagsForResource</code> request where <code>limit</code> was used and the
  ##          results exceeded the value of that parameter. Pagination continues from the end of the
  ##          previous results that returned the <code>nextToken</code> value.
  ##   limit: int
  ##        : The maximum number of tag results returned by <code>ListTagsForResource</code> in
  ##          paginated output. When this parameter is used, <code>ListTagsForResource</code> returns
  ##          only <code>limit</code> results in a single page along with a <code>nextToken</code>
  ##          response element. You can see the remaining results of the initial request by sending
  ##          another <code>ListTagsForResource</code> request with the returned <code>nextToken</code>
  ##          value. This value can be between 1 and 100. If you don't use
  ##          this parameter, <code>ListTagsForResource</code> returns up to 100
  ##          results and a <code>nextToken</code> value if applicable.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) that identifies the resource to list the tags for.
  var query_593372 = newJObject()
  add(query_593372, "nextToken", newJString(nextToken))
  add(query_593372, "limit", newJInt(limit))
  add(query_593372, "resourceArn", newJString(resourceArn))
  result = call_593371.call(nil, query_593372, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_593357(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "appmesh.amazonaws.com", route: "/v20190125/tags#resourceArn",
    validator: validate_ListTagsForResource_593358, base: "/",
    url: url_ListTagsForResource_593359, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_593373 = ref object of OpenApiRestCall_592364
proc url_TagResource_593375(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TagResource_593374(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Associates the specified tags to a resource with the specified <code>resourceArn</code>.
  ##          If existing tags on a resource aren't specified in the request parameters, they aren't
  ##          changed. When a resource is deleted, the tags associated with that resource are also
  ##          deleted.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   resourceArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the resource to add tags to.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `resourceArn` field"
  var valid_593376 = query.getOrDefault("resourceArn")
  valid_593376 = validateParameter(valid_593376, JString, required = true,
                                 default = nil)
  if valid_593376 != nil:
    section.add "resourceArn", valid_593376
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593377 = header.getOrDefault("X-Amz-Signature")
  valid_593377 = validateParameter(valid_593377, JString, required = false,
                                 default = nil)
  if valid_593377 != nil:
    section.add "X-Amz-Signature", valid_593377
  var valid_593378 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593378 = validateParameter(valid_593378, JString, required = false,
                                 default = nil)
  if valid_593378 != nil:
    section.add "X-Amz-Content-Sha256", valid_593378
  var valid_593379 = header.getOrDefault("X-Amz-Date")
  valid_593379 = validateParameter(valid_593379, JString, required = false,
                                 default = nil)
  if valid_593379 != nil:
    section.add "X-Amz-Date", valid_593379
  var valid_593380 = header.getOrDefault("X-Amz-Credential")
  valid_593380 = validateParameter(valid_593380, JString, required = false,
                                 default = nil)
  if valid_593380 != nil:
    section.add "X-Amz-Credential", valid_593380
  var valid_593381 = header.getOrDefault("X-Amz-Security-Token")
  valid_593381 = validateParameter(valid_593381, JString, required = false,
                                 default = nil)
  if valid_593381 != nil:
    section.add "X-Amz-Security-Token", valid_593381
  var valid_593382 = header.getOrDefault("X-Amz-Algorithm")
  valid_593382 = validateParameter(valid_593382, JString, required = false,
                                 default = nil)
  if valid_593382 != nil:
    section.add "X-Amz-Algorithm", valid_593382
  var valid_593383 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593383 = validateParameter(valid_593383, JString, required = false,
                                 default = nil)
  if valid_593383 != nil:
    section.add "X-Amz-SignedHeaders", valid_593383
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593385: Call_TagResource_593373; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates the specified tags to a resource with the specified <code>resourceArn</code>.
  ##          If existing tags on a resource aren't specified in the request parameters, they aren't
  ##          changed. When a resource is deleted, the tags associated with that resource are also
  ##          deleted.
  ## 
  let valid = call_593385.validator(path, query, header, formData, body)
  let scheme = call_593385.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593385.url(scheme.get, call_593385.host, call_593385.base,
                         call_593385.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593385, url, valid)

proc call*(call_593386: Call_TagResource_593373; body: JsonNode; resourceArn: string): Recallable =
  ## tagResource
  ## Associates the specified tags to a resource with the specified <code>resourceArn</code>.
  ##          If existing tags on a resource aren't specified in the request parameters, they aren't
  ##          changed. When a resource is deleted, the tags associated with that resource are also
  ##          deleted.
  ##   body: JObject (required)
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource to add tags to.
  var query_593387 = newJObject()
  var body_593388 = newJObject()
  if body != nil:
    body_593388 = body
  add(query_593387, "resourceArn", newJString(resourceArn))
  result = call_593386.call(nil, query_593387, nil, nil, body_593388)

var tagResource* = Call_TagResource_593373(name: "tagResource",
                                        meth: HttpMethod.HttpPut,
                                        host: "appmesh.amazonaws.com",
                                        route: "/v20190125/tag#resourceArn",
                                        validator: validate_TagResource_593374,
                                        base: "/", url: url_TagResource_593375,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_593389 = ref object of OpenApiRestCall_592364
proc url_UntagResource_593391(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UntagResource_593390(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes specified tags from a resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   resourceArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the resource to delete tags from.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `resourceArn` field"
  var valid_593392 = query.getOrDefault("resourceArn")
  valid_593392 = validateParameter(valid_593392, JString, required = true,
                                 default = nil)
  if valid_593392 != nil:
    section.add "resourceArn", valid_593392
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593393 = header.getOrDefault("X-Amz-Signature")
  valid_593393 = validateParameter(valid_593393, JString, required = false,
                                 default = nil)
  if valid_593393 != nil:
    section.add "X-Amz-Signature", valid_593393
  var valid_593394 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593394 = validateParameter(valid_593394, JString, required = false,
                                 default = nil)
  if valid_593394 != nil:
    section.add "X-Amz-Content-Sha256", valid_593394
  var valid_593395 = header.getOrDefault("X-Amz-Date")
  valid_593395 = validateParameter(valid_593395, JString, required = false,
                                 default = nil)
  if valid_593395 != nil:
    section.add "X-Amz-Date", valid_593395
  var valid_593396 = header.getOrDefault("X-Amz-Credential")
  valid_593396 = validateParameter(valid_593396, JString, required = false,
                                 default = nil)
  if valid_593396 != nil:
    section.add "X-Amz-Credential", valid_593396
  var valid_593397 = header.getOrDefault("X-Amz-Security-Token")
  valid_593397 = validateParameter(valid_593397, JString, required = false,
                                 default = nil)
  if valid_593397 != nil:
    section.add "X-Amz-Security-Token", valid_593397
  var valid_593398 = header.getOrDefault("X-Amz-Algorithm")
  valid_593398 = validateParameter(valid_593398, JString, required = false,
                                 default = nil)
  if valid_593398 != nil:
    section.add "X-Amz-Algorithm", valid_593398
  var valid_593399 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593399 = validateParameter(valid_593399, JString, required = false,
                                 default = nil)
  if valid_593399 != nil:
    section.add "X-Amz-SignedHeaders", valid_593399
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593401: Call_UntagResource_593389; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes specified tags from a resource.
  ## 
  let valid = call_593401.validator(path, query, header, formData, body)
  let scheme = call_593401.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593401.url(scheme.get, call_593401.host, call_593401.base,
                         call_593401.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593401, url, valid)

proc call*(call_593402: Call_UntagResource_593389; body: JsonNode;
          resourceArn: string): Recallable =
  ## untagResource
  ## Deletes specified tags from a resource.
  ##   body: JObject (required)
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource to delete tags from.
  var query_593403 = newJObject()
  var body_593404 = newJObject()
  if body != nil:
    body_593404 = body
  add(query_593403, "resourceArn", newJString(resourceArn))
  result = call_593402.call(nil, query_593403, nil, nil, body_593404)

var untagResource* = Call_UntagResource_593389(name: "untagResource",
    meth: HttpMethod.HttpPut, host: "appmesh.amazonaws.com",
    route: "/v20190125/untag#resourceArn", validator: validate_UntagResource_593390,
    base: "/", url: url_UntagResource_593391, schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc sign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", "")
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", "")
    region = os.getEnv("AWS_REGION", "")
  assert secret != "", "need secret key in env"
  assert access != "", "need access key in env"
  assert region != "", "need region in env"
  var
    normal: PathNormal
    url = normalizeUrl(recall.url, query, normalize = normal)
    scheme = parseEnum[Scheme](url.scheme)
  assert scheme in awsServers, "unknown scheme `" & $scheme & "`"
  assert region in awsServers[scheme], "unknown region `" & region & "`"
  url.hostname = awsServers[scheme][region]
  case awsServiceName.toLowerAscii
  of "s3":
    normal = PathNormal.S3
  else:
    normal = PathNormal.Default
  recall.headers["Host"] = url.hostname
  recall.headers["X-Amz-Date"] = date
  let
    algo = SHA256
    scope = credentialScope(region = region, service = awsServiceName, date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers, recall.body,
                             normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date, region = region,
                                 service = awsServiceName, sts, digest = algo)
  var auth = $algo & " "
  auth &= "Credential=" & access / scope & ", "
  auth &= "SignedHeaders=" & recall.headers.signedHeaders & ", "
  auth &= "Signature=" & signature
  recall.headers["Authorization"] = auth
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.sign(input.getOrDefault("query"), SHA256)
