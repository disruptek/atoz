
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS App Mesh
## version: 2018-10-01
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p>AWS App Mesh is a service mesh based on the Envoy proxy that makes it easy to monitor and
##          control containerized microservices. App Mesh standardizes how your microservices
##          communicate, giving you end-to-end visibility and helping to ensure high-availability for
##          your applications.</p>
##          <p>App Mesh gives you consistent visibility and network traffic controls for every
##          microservice in an application. You can use App Mesh with Amazon ECS
##          (using the Amazon EC2 launch type), Amazon EKS, and Kubernetes on AWS.</p>
##          <note>
##             <p>App Mesh supports containerized microservice applications that use service discovery
##             naming for their components. To use App Mesh, you must have a containerized application
##             running on Amazon EC2 instances, hosted in either Amazon ECS, Amazon EKS, or Kubernetes on AWS. For
##             more information about service discovery on Amazon ECS, see <a href="http://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-discovery.html">Service Discovery</a> in the
##                <i>Amazon Elastic Container Service Developer Guide</i>. Kubernetes <code>kube-dns</code> is supported.
##             For more information, see <a href="https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/">DNS
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
  ## <p>Creates a new service mesh. A service mesh is a logical boundary for network traffic
  ##          between the services that reside within it.</p>
  ##          <p>After you create your service mesh, you can create virtual nodes, virtual routers, and
  ##          routes to distribute traffic between the applications in your mesh.</p>
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
  ## <p>Creates a new service mesh. A service mesh is a logical boundary for network traffic
  ##          between the services that reside within it.</p>
  ##          <p>After you create your service mesh, you can create virtual nodes, virtual routers, and
  ##          routes to distribute traffic between the applications in your mesh.</p>
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
  ## <p>Creates a new service mesh. A service mesh is a logical boundary for network traffic
  ##          between the services that reside within it.</p>
  ##          <p>After you create your service mesh, you can create virtual nodes, virtual routers, and
  ##          routes to distribute traffic between the applications in your mesh.</p>
  ##   body: JObject (required)
  var body_592973 = newJObject()
  if body != nil:
    body_592973 = body
  result = call_592972.call(nil, nil, nil, nil, body_592973)

var createMesh* = Call_CreateMesh_592960(name: "createMesh",
                                      meth: HttpMethod.HttpPut,
                                      host: "appmesh.amazonaws.com",
                                      route: "/meshes",
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
  ##          <code>ListMeshes</code> request where <code>limit</code> was used and the
  ##          results exceeded the value of that parameter. Pagination continues from the end of the
  ##          previous results that returned the <code>nextToken</code> value.</p>
  ##          <note>
  ##             <p>This token should be treated as an opaque identifier that is only used to
  ##                 retrieve the next items in a list and not for other programmatic purposes.</p>
  ##         </note>
  ##   limit: JInt
  ##        : The maximum number of mesh results returned by <code>ListMeshes</code> in paginated
  ##          output. When this parameter is used, <code>ListMeshes</code> only returns
  ##             <code>limit</code> results in a single page along with a <code>nextToken</code> response
  ##          element. The remaining results of the initial request can be seen by sending another
  ##             <code>ListMeshes</code> request with the returned <code>nextToken</code> value. This
  ##          value can be between 1 and 100. If this parameter is not
  ##          used, then <code>ListMeshes</code> returns up to 100 results and a
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
  ##          <code>ListMeshes</code> request where <code>limit</code> was used and the
  ##          results exceeded the value of that parameter. Pagination continues from the end of the
  ##          previous results that returned the <code>nextToken</code> value.</p>
  ##          <note>
  ##             <p>This token should be treated as an opaque identifier that is only used to
  ##                 retrieve the next items in a list and not for other programmatic purposes.</p>
  ##         </note>
  ##   limit: int
  ##        : The maximum number of mesh results returned by <code>ListMeshes</code> in paginated
  ##          output. When this parameter is used, <code>ListMeshes</code> only returns
  ##             <code>limit</code> results in a single page along with a <code>nextToken</code> response
  ##          element. The remaining results of the initial request can be seen by sending another
  ##             <code>ListMeshes</code> request with the returned <code>nextToken</code> value. This
  ##          value can be between 1 and 100. If this parameter is not
  ##          used, then <code>ListMeshes</code> returns up to 100 results and a
  ##             <code>nextToken</code> value if applicable.
  var query_592920 = newJObject()
  add(query_592920, "nextToken", newJString(nextToken))
  add(query_592920, "limit", newJInt(limit))
  result = call_592919.call(nil, query_592920, nil, nil, nil)

var listMeshes* = Call_ListMeshes_592703(name: "listMeshes",
                                      meth: HttpMethod.HttpGet,
                                      host: "appmesh.amazonaws.com",
                                      route: "/meshes",
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
    segments = @[(kind: ConstantSegment, value: "/meshes/"),
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
  ## <p>Creates a new route that is associated with a virtual router.</p>
  ##          <p>You can use the <code>prefix</code> parameter in your route specification for path-based
  ##          routing of requests. For example, if your virtual router service name is
  ##             <code>my-service.local</code>, and you want the route to match requests to
  ##             <code>my-service.local/metrics</code>, then your prefix should be
  ##          <code>/metrics</code>.</p>
  ##          <p>If your route matches a request, you can distribute traffic to one or more target
  ##          virtual nodes with relative weighting.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh in which to create the route.
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
  ## <p>Creates a new route that is associated with a virtual router.</p>
  ##          <p>You can use the <code>prefix</code> parameter in your route specification for path-based
  ##          routing of requests. For example, if your virtual router service name is
  ##             <code>my-service.local</code>, and you want the route to match requests to
  ##             <code>my-service.local/metrics</code>, then your prefix should be
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
  ## <p>Creates a new route that is associated with a virtual router.</p>
  ##          <p>You can use the <code>prefix</code> parameter in your route specification for path-based
  ##          routing of requests. For example, if your virtual router service name is
  ##             <code>my-service.local</code>, and you want the route to match requests to
  ##             <code>my-service.local/metrics</code>, then your prefix should be
  ##          <code>/metrics</code>.</p>
  ##          <p>If your route matches a request, you can distribute traffic to one or more target
  ##          virtual nodes with relative weighting.</p>
  ##   meshName: string (required)
  ##           : The name of the service mesh in which to create the route.
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
                                        host: "appmesh.amazonaws.com", route: "/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes",
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
    segments = @[(kind: ConstantSegment, value: "/meshes/"),
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
  ##           : The name of the service mesh in which to list routes.
  ##   virtualRouterName: JString (required)
  ##                    : The name of the virtual router in which to list routes.
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
  ##          <code>ListRoutes</code> request where <code>limit</code> was used and the
  ##          results exceeded the value of that parameter. Pagination continues from the end of the
  ##          previous results that returned the <code>nextToken</code> value.
  ##   limit: JInt
  ##        : The maximum number of mesh results returned by <code>ListRoutes</code> in paginated
  ##          output. When this parameter is used, <code>ListRoutes</code> only returns
  ##             <code>limit</code> results in a single page along with a <code>nextToken</code> response
  ##          element. The remaining results of the initial request can be seen by sending another
  ##             <code>ListRoutes</code> request with the returned <code>nextToken</code> value. This
  ##          value can be between 1 and 100. If this parameter is not
  ##          used, then <code>ListRoutes</code> returns up to 100 results and a
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
  ##          <code>ListRoutes</code> request where <code>limit</code> was used and the
  ##          results exceeded the value of that parameter. Pagination continues from the end of the
  ##          previous results that returned the <code>nextToken</code> value.
  ##   limit: int
  ##        : The maximum number of mesh results returned by <code>ListRoutes</code> in paginated
  ##          output. When this parameter is used, <code>ListRoutes</code> only returns
  ##             <code>limit</code> results in a single page along with a <code>nextToken</code> response
  ##          element. The remaining results of the initial request can be seen by sending another
  ##             <code>ListRoutes</code> request with the returned <code>nextToken</code> value. This
  ##          value can be between 1 and 100. If this parameter is not
  ##          used, then <code>ListRoutes</code> returns up to 100 results and a
  ##             <code>nextToken</code> value if applicable.
  ##   meshName: string (required)
  ##           : The name of the service mesh in which to list routes.
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router in which to list routes.
  var path_593004 = newJObject()
  var query_593005 = newJObject()
  add(query_593005, "nextToken", newJString(nextToken))
  add(query_593005, "limit", newJInt(limit))
  add(path_593004, "meshName", newJString(meshName))
  add(path_593004, "virtualRouterName", newJString(virtualRouterName))
  result = call_593003.call(path_593004, query_593005, nil, nil, nil)

var listRoutes* = Call_ListRoutes_592974(name: "listRoutes",
                                      meth: HttpMethod.HttpGet,
                                      host: "appmesh.amazonaws.com", route: "/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes",
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
    segments = @[(kind: ConstantSegment, value: "/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualNodes")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_CreateVirtualNode_593041(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Creates a new virtual node within a service mesh.</p>
  ##          <p>A virtual node acts as logical pointer to a particular task group, such as an Amazon ECS
  ##          service or a Kubernetes deployment. When you create a virtual node, you must specify the
  ##          DNS service discovery name for your task group.</p>
  ##          <p>Any inbound traffic that your virtual node expects should be specified as a
  ##             <code>listener</code>. Any outbound traffic that your virtual node expects to reach
  ##          should be specified as a <code>backend</code>.</p>
  ##          <p>The response metadata for your new virtual node contains the <code>arn</code> that is
  ##          associated with the virtual node. Set this value (either the full ARN or the truncated
  ##          resource name, for example, <code>mesh/default/virtualNode/simpleapp</code>, as the
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
  ##           : The name of the service mesh in which to create the virtual node.
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
  ## <p>Creates a new virtual node within a service mesh.</p>
  ##          <p>A virtual node acts as logical pointer to a particular task group, such as an Amazon ECS
  ##          service or a Kubernetes deployment. When you create a virtual node, you must specify the
  ##          DNS service discovery name for your task group.</p>
  ##          <p>Any inbound traffic that your virtual node expects should be specified as a
  ##             <code>listener</code>. Any outbound traffic that your virtual node expects to reach
  ##          should be specified as a <code>backend</code>.</p>
  ##          <p>The response metadata for your new virtual node contains the <code>arn</code> that is
  ##          associated with the virtual node. Set this value (either the full ARN or the truncated
  ##          resource name, for example, <code>mesh/default/virtualNode/simpleapp</code>, as the
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
  ## <p>Creates a new virtual node within a service mesh.</p>
  ##          <p>A virtual node acts as logical pointer to a particular task group, such as an Amazon ECS
  ##          service or a Kubernetes deployment. When you create a virtual node, you must specify the
  ##          DNS service discovery name for your task group.</p>
  ##          <p>Any inbound traffic that your virtual node expects should be specified as a
  ##             <code>listener</code>. Any outbound traffic that your virtual node expects to reach
  ##          should be specified as a <code>backend</code>.</p>
  ##          <p>The response metadata for your new virtual node contains the <code>arn</code> that is
  ##          associated with the virtual node. Set this value (either the full ARN or the truncated
  ##          resource name, for example, <code>mesh/default/virtualNode/simpleapp</code>, as the
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
  ##           : The name of the service mesh in which to create the virtual node.
  ##   body: JObject (required)
  var path_593054 = newJObject()
  var body_593055 = newJObject()
  add(path_593054, "meshName", newJString(meshName))
  if body != nil:
    body_593055 = body
  result = call_593053.call(path_593054, nil, nil, nil, body_593055)

var createVirtualNode* = Call_CreateVirtualNode_593040(name: "createVirtualNode",
    meth: HttpMethod.HttpPut, host: "appmesh.amazonaws.com",
    route: "/meshes/{meshName}/virtualNodes",
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
    segments = @[(kind: ConstantSegment, value: "/meshes/"),
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
  ##           : The name of the service mesh in which to list virtual nodes.
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
  ##          <code>ListVirtualNodes</code> request where <code>limit</code> was used and the
  ##          results exceeded the value of that parameter. Pagination continues from the end of the
  ##          previous results that returned the <code>nextToken</code> value.
  ##   limit: JInt
  ##        : The maximum number of mesh results returned by <code>ListVirtualNodes</code> in
  ##          paginated output. When this parameter is used, <code>ListVirtualNodes</code> only returns
  ##          <code>limit</code> results in a single page along with a <code>nextToken</code>
  ##          response element. The remaining results of the initial request can be seen by sending
  ##          another <code>ListVirtualNodes</code> request with the returned <code>nextToken</code>
  ##          value. This value can be between 1 and 100. If this
  ##          parameter is not used, then <code>ListVirtualNodes</code> returns up to
  ##          100 results and a <code>nextToken</code> value if applicable.
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
  ##          <code>ListVirtualNodes</code> request where <code>limit</code> was used and the
  ##          results exceeded the value of that parameter. Pagination continues from the end of the
  ##          previous results that returned the <code>nextToken</code> value.
  ##   limit: int
  ##        : The maximum number of mesh results returned by <code>ListVirtualNodes</code> in
  ##          paginated output. When this parameter is used, <code>ListVirtualNodes</code> only returns
  ##          <code>limit</code> results in a single page along with a <code>nextToken</code>
  ##          response element. The remaining results of the initial request can be seen by sending
  ##          another <code>ListVirtualNodes</code> request with the returned <code>nextToken</code>
  ##          value. This value can be between 1 and 100. If this
  ##          parameter is not used, then <code>ListVirtualNodes</code> returns up to
  ##          100 results and a <code>nextToken</code> value if applicable.
  ##   meshName: string (required)
  ##           : The name of the service mesh in which to list virtual nodes.
  var path_593038 = newJObject()
  var query_593039 = newJObject()
  add(query_593039, "nextToken", newJString(nextToken))
  add(query_593039, "limit", newJInt(limit))
  add(path_593038, "meshName", newJString(meshName))
  result = call_593037.call(path_593038, query_593039, nil, nil, nil)

var listVirtualNodes* = Call_ListVirtualNodes_593023(name: "listVirtualNodes",
    meth: HttpMethod.HttpGet, host: "appmesh.amazonaws.com",
    route: "/meshes/{meshName}/virtualNodes",
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
    segments = @[(kind: ConstantSegment, value: "/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualRouters")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_CreateVirtualRouter_593074(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Creates a new virtual router within a service mesh.</p>
  ##          <p>Virtual routers handle traffic for one or more service names within your mesh. After you
  ##          create your virtual router, create and associate routes for your virtual router that direct
  ##          incoming requests to different virtual nodes.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh in which to create the virtual router.
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
  ## <p>Creates a new virtual router within a service mesh.</p>
  ##          <p>Virtual routers handle traffic for one or more service names within your mesh. After you
  ##          create your virtual router, create and associate routes for your virtual router that direct
  ##          incoming requests to different virtual nodes.</p>
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
  ## <p>Creates a new virtual router within a service mesh.</p>
  ##          <p>Virtual routers handle traffic for one or more service names within your mesh. After you
  ##          create your virtual router, create and associate routes for your virtual router that direct
  ##          incoming requests to different virtual nodes.</p>
  ##   meshName: string (required)
  ##           : The name of the service mesh in which to create the virtual router.
  ##   body: JObject (required)
  var path_593087 = newJObject()
  var body_593088 = newJObject()
  add(path_593087, "meshName", newJString(meshName))
  if body != nil:
    body_593088 = body
  result = call_593086.call(path_593087, nil, nil, nil, body_593088)

var createVirtualRouter* = Call_CreateVirtualRouter_593073(
    name: "createVirtualRouter", meth: HttpMethod.HttpPut,
    host: "appmesh.amazonaws.com", route: "/meshes/{meshName}/virtualRouters",
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
    segments = @[(kind: ConstantSegment, value: "/meshes/"),
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
  ##           : The name of the service mesh in which to list virtual routers.
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
  ##          <code>ListVirtualRouters</code> request where <code>limit</code> was used and the
  ##          results exceeded the value of that parameter. Pagination continues from the end of the
  ##          previous results that returned the <code>nextToken</code> value.
  ##   limit: JInt
  ##        : The maximum number of mesh results returned by <code>ListVirtualRouters</code> in
  ##          paginated output. When this parameter is used, <code>ListVirtualRouters</code> only returns
  ##          <code>limit</code> results in a single page along with a <code>nextToken</code>
  ##          response element. The remaining results of the initial request can be seen by sending
  ##          another <code>ListVirtualRouters</code> request with the returned <code>nextToken</code>
  ##          value. This value can be between 1 and 100. If this
  ##          parameter is not used, then <code>ListVirtualRouters</code> returns up to
  ##          100 results and a <code>nextToken</code> value if applicable.
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
  ##          <code>ListVirtualRouters</code> request where <code>limit</code> was used and the
  ##          results exceeded the value of that parameter. Pagination continues from the end of the
  ##          previous results that returned the <code>nextToken</code> value.
  ##   limit: int
  ##        : The maximum number of mesh results returned by <code>ListVirtualRouters</code> in
  ##          paginated output. When this parameter is used, <code>ListVirtualRouters</code> only returns
  ##          <code>limit</code> results in a single page along with a <code>nextToken</code>
  ##          response element. The remaining results of the initial request can be seen by sending
  ##          another <code>ListVirtualRouters</code> request with the returned <code>nextToken</code>
  ##          value. This value can be between 1 and 100. If this
  ##          parameter is not used, then <code>ListVirtualRouters</code> returns up to
  ##          100 results and a <code>nextToken</code> value if applicable.
  ##   meshName: string (required)
  ##           : The name of the service mesh in which to list virtual routers.
  var path_593071 = newJObject()
  var query_593072 = newJObject()
  add(query_593072, "nextToken", newJString(nextToken))
  add(query_593072, "limit", newJInt(limit))
  add(path_593071, "meshName", newJString(meshName))
  result = call_593070.call(path_593071, query_593072, nil, nil, nil)

var listVirtualRouters* = Call_ListVirtualRouters_593056(
    name: "listVirtualRouters", meth: HttpMethod.HttpGet,
    host: "appmesh.amazonaws.com", route: "/meshes/{meshName}/virtualRouters",
    validator: validate_ListVirtualRouters_593057, base: "/",
    url: url_ListVirtualRouters_593058, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMesh_593089 = ref object of OpenApiRestCall_592364
proc url_DescribeMesh_593091(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/meshes/"),
               (kind: VariableSegment, value: "meshName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DescribeMesh_593090(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593092 = path.getOrDefault("meshName")
  valid_593092 = validateParameter(valid_593092, JString, required = true,
                                 default = nil)
  if valid_593092 != nil:
    section.add "meshName", valid_593092
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
  var valid_593093 = header.getOrDefault("X-Amz-Signature")
  valid_593093 = validateParameter(valid_593093, JString, required = false,
                                 default = nil)
  if valid_593093 != nil:
    section.add "X-Amz-Signature", valid_593093
  var valid_593094 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593094 = validateParameter(valid_593094, JString, required = false,
                                 default = nil)
  if valid_593094 != nil:
    section.add "X-Amz-Content-Sha256", valid_593094
  var valid_593095 = header.getOrDefault("X-Amz-Date")
  valid_593095 = validateParameter(valid_593095, JString, required = false,
                                 default = nil)
  if valid_593095 != nil:
    section.add "X-Amz-Date", valid_593095
  var valid_593096 = header.getOrDefault("X-Amz-Credential")
  valid_593096 = validateParameter(valid_593096, JString, required = false,
                                 default = nil)
  if valid_593096 != nil:
    section.add "X-Amz-Credential", valid_593096
  var valid_593097 = header.getOrDefault("X-Amz-Security-Token")
  valid_593097 = validateParameter(valid_593097, JString, required = false,
                                 default = nil)
  if valid_593097 != nil:
    section.add "X-Amz-Security-Token", valid_593097
  var valid_593098 = header.getOrDefault("X-Amz-Algorithm")
  valid_593098 = validateParameter(valid_593098, JString, required = false,
                                 default = nil)
  if valid_593098 != nil:
    section.add "X-Amz-Algorithm", valid_593098
  var valid_593099 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593099 = validateParameter(valid_593099, JString, required = false,
                                 default = nil)
  if valid_593099 != nil:
    section.add "X-Amz-SignedHeaders", valid_593099
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593100: Call_DescribeMesh_593089; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an existing service mesh.
  ## 
  let valid = call_593100.validator(path, query, header, formData, body)
  let scheme = call_593100.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593100.url(scheme.get, call_593100.host, call_593100.base,
                         call_593100.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593100, url, valid)

proc call*(call_593101: Call_DescribeMesh_593089; meshName: string): Recallable =
  ## describeMesh
  ## Describes an existing service mesh.
  ##   meshName: string (required)
  ##           : The name of the service mesh to describe.
  var path_593102 = newJObject()
  add(path_593102, "meshName", newJString(meshName))
  result = call_593101.call(path_593102, nil, nil, nil, nil)

var describeMesh* = Call_DescribeMesh_593089(name: "describeMesh",
    meth: HttpMethod.HttpGet, host: "appmesh.amazonaws.com",
    route: "/meshes/{meshName}", validator: validate_DescribeMesh_593090, base: "/",
    url: url_DescribeMesh_593091, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMesh_593103 = ref object of OpenApiRestCall_592364
proc url_DeleteMesh_593105(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/meshes/"),
               (kind: VariableSegment, value: "meshName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteMesh_593104(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes an existing service mesh.</p>
  ##          <p>You must delete all resources (routes, virtual routers, virtual nodes) in the service
  ##          mesh before you can delete the mesh itself.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_593106 = path.getOrDefault("meshName")
  valid_593106 = validateParameter(valid_593106, JString, required = true,
                                 default = nil)
  if valid_593106 != nil:
    section.add "meshName", valid_593106
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
  var valid_593107 = header.getOrDefault("X-Amz-Signature")
  valid_593107 = validateParameter(valid_593107, JString, required = false,
                                 default = nil)
  if valid_593107 != nil:
    section.add "X-Amz-Signature", valid_593107
  var valid_593108 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593108 = validateParameter(valid_593108, JString, required = false,
                                 default = nil)
  if valid_593108 != nil:
    section.add "X-Amz-Content-Sha256", valid_593108
  var valid_593109 = header.getOrDefault("X-Amz-Date")
  valid_593109 = validateParameter(valid_593109, JString, required = false,
                                 default = nil)
  if valid_593109 != nil:
    section.add "X-Amz-Date", valid_593109
  var valid_593110 = header.getOrDefault("X-Amz-Credential")
  valid_593110 = validateParameter(valid_593110, JString, required = false,
                                 default = nil)
  if valid_593110 != nil:
    section.add "X-Amz-Credential", valid_593110
  var valid_593111 = header.getOrDefault("X-Amz-Security-Token")
  valid_593111 = validateParameter(valid_593111, JString, required = false,
                                 default = nil)
  if valid_593111 != nil:
    section.add "X-Amz-Security-Token", valid_593111
  var valid_593112 = header.getOrDefault("X-Amz-Algorithm")
  valid_593112 = validateParameter(valid_593112, JString, required = false,
                                 default = nil)
  if valid_593112 != nil:
    section.add "X-Amz-Algorithm", valid_593112
  var valid_593113 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593113 = validateParameter(valid_593113, JString, required = false,
                                 default = nil)
  if valid_593113 != nil:
    section.add "X-Amz-SignedHeaders", valid_593113
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593114: Call_DeleteMesh_593103; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an existing service mesh.</p>
  ##          <p>You must delete all resources (routes, virtual routers, virtual nodes) in the service
  ##          mesh before you can delete the mesh itself.</p>
  ## 
  let valid = call_593114.validator(path, query, header, formData, body)
  let scheme = call_593114.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593114.url(scheme.get, call_593114.host, call_593114.base,
                         call_593114.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593114, url, valid)

proc call*(call_593115: Call_DeleteMesh_593103; meshName: string): Recallable =
  ## deleteMesh
  ## <p>Deletes an existing service mesh.</p>
  ##          <p>You must delete all resources (routes, virtual routers, virtual nodes) in the service
  ##          mesh before you can delete the mesh itself.</p>
  ##   meshName: string (required)
  ##           : The name of the service mesh to delete.
  var path_593116 = newJObject()
  add(path_593116, "meshName", newJString(meshName))
  result = call_593115.call(path_593116, nil, nil, nil, nil)

var deleteMesh* = Call_DeleteMesh_593103(name: "deleteMesh",
                                      meth: HttpMethod.HttpDelete,
                                      host: "appmesh.amazonaws.com",
                                      route: "/meshes/{meshName}",
                                      validator: validate_DeleteMesh_593104,
                                      base: "/", url: url_DeleteMesh_593105,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRoute_593133 = ref object of OpenApiRestCall_592364
proc url_UpdateRoute_593135(protocol: Scheme; host: string; base: string;
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
    segments = @[(kind: ConstantSegment, value: "/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualRouter/"),
               (kind: VariableSegment, value: "virtualRouterName"),
               (kind: ConstantSegment, value: "/routes/"),
               (kind: VariableSegment, value: "routeName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UpdateRoute_593134(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates an existing route for a specified service mesh and virtual router.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   routeName: JString (required)
  ##            : The name of the route to update.
  ##   meshName: JString (required)
  ##           : The name of the service mesh in which the route resides.
  ##   virtualRouterName: JString (required)
  ##                    : The name of the virtual router with which the route is associated.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `routeName` field"
  var valid_593136 = path.getOrDefault("routeName")
  valid_593136 = validateParameter(valid_593136, JString, required = true,
                                 default = nil)
  if valid_593136 != nil:
    section.add "routeName", valid_593136
  var valid_593137 = path.getOrDefault("meshName")
  valid_593137 = validateParameter(valid_593137, JString, required = true,
                                 default = nil)
  if valid_593137 != nil:
    section.add "meshName", valid_593137
  var valid_593138 = path.getOrDefault("virtualRouterName")
  valid_593138 = validateParameter(valid_593138, JString, required = true,
                                 default = nil)
  if valid_593138 != nil:
    section.add "virtualRouterName", valid_593138
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
  var valid_593139 = header.getOrDefault("X-Amz-Signature")
  valid_593139 = validateParameter(valid_593139, JString, required = false,
                                 default = nil)
  if valid_593139 != nil:
    section.add "X-Amz-Signature", valid_593139
  var valid_593140 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593140 = validateParameter(valid_593140, JString, required = false,
                                 default = nil)
  if valid_593140 != nil:
    section.add "X-Amz-Content-Sha256", valid_593140
  var valid_593141 = header.getOrDefault("X-Amz-Date")
  valid_593141 = validateParameter(valid_593141, JString, required = false,
                                 default = nil)
  if valid_593141 != nil:
    section.add "X-Amz-Date", valid_593141
  var valid_593142 = header.getOrDefault("X-Amz-Credential")
  valid_593142 = validateParameter(valid_593142, JString, required = false,
                                 default = nil)
  if valid_593142 != nil:
    section.add "X-Amz-Credential", valid_593142
  var valid_593143 = header.getOrDefault("X-Amz-Security-Token")
  valid_593143 = validateParameter(valid_593143, JString, required = false,
                                 default = nil)
  if valid_593143 != nil:
    section.add "X-Amz-Security-Token", valid_593143
  var valid_593144 = header.getOrDefault("X-Amz-Algorithm")
  valid_593144 = validateParameter(valid_593144, JString, required = false,
                                 default = nil)
  if valid_593144 != nil:
    section.add "X-Amz-Algorithm", valid_593144
  var valid_593145 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593145 = validateParameter(valid_593145, JString, required = false,
                                 default = nil)
  if valid_593145 != nil:
    section.add "X-Amz-SignedHeaders", valid_593145
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593147: Call_UpdateRoute_593133; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing route for a specified service mesh and virtual router.
  ## 
  let valid = call_593147.validator(path, query, header, formData, body)
  let scheme = call_593147.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593147.url(scheme.get, call_593147.host, call_593147.base,
                         call_593147.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593147, url, valid)

proc call*(call_593148: Call_UpdateRoute_593133; routeName: string; meshName: string;
          body: JsonNode; virtualRouterName: string): Recallable =
  ## updateRoute
  ## Updates an existing route for a specified service mesh and virtual router.
  ##   routeName: string (required)
  ##            : The name of the route to update.
  ##   meshName: string (required)
  ##           : The name of the service mesh in which the route resides.
  ##   body: JObject (required)
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router with which the route is associated.
  var path_593149 = newJObject()
  var body_593150 = newJObject()
  add(path_593149, "routeName", newJString(routeName))
  add(path_593149, "meshName", newJString(meshName))
  if body != nil:
    body_593150 = body
  add(path_593149, "virtualRouterName", newJString(virtualRouterName))
  result = call_593148.call(path_593149, nil, nil, nil, body_593150)

var updateRoute* = Call_UpdateRoute_593133(name: "updateRoute",
                                        meth: HttpMethod.HttpPut,
                                        host: "appmesh.amazonaws.com", route: "/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes/{routeName}",
                                        validator: validate_UpdateRoute_593134,
                                        base: "/", url: url_UpdateRoute_593135,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRoute_593117 = ref object of OpenApiRestCall_592364
proc url_DescribeRoute_593119(protocol: Scheme; host: string; base: string;
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
    segments = @[(kind: ConstantSegment, value: "/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualRouter/"),
               (kind: VariableSegment, value: "virtualRouterName"),
               (kind: ConstantSegment, value: "/routes/"),
               (kind: VariableSegment, value: "routeName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DescribeRoute_593118(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes an existing route.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   routeName: JString (required)
  ##            : The name of the route to describe.
  ##   meshName: JString (required)
  ##           : The name of the service mesh in which the route resides.
  ##   virtualRouterName: JString (required)
  ##                    : The name of the virtual router with which the route is associated.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `routeName` field"
  var valid_593120 = path.getOrDefault("routeName")
  valid_593120 = validateParameter(valid_593120, JString, required = true,
                                 default = nil)
  if valid_593120 != nil:
    section.add "routeName", valid_593120
  var valid_593121 = path.getOrDefault("meshName")
  valid_593121 = validateParameter(valid_593121, JString, required = true,
                                 default = nil)
  if valid_593121 != nil:
    section.add "meshName", valid_593121
  var valid_593122 = path.getOrDefault("virtualRouterName")
  valid_593122 = validateParameter(valid_593122, JString, required = true,
                                 default = nil)
  if valid_593122 != nil:
    section.add "virtualRouterName", valid_593122
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
  var valid_593123 = header.getOrDefault("X-Amz-Signature")
  valid_593123 = validateParameter(valid_593123, JString, required = false,
                                 default = nil)
  if valid_593123 != nil:
    section.add "X-Amz-Signature", valid_593123
  var valid_593124 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593124 = validateParameter(valid_593124, JString, required = false,
                                 default = nil)
  if valid_593124 != nil:
    section.add "X-Amz-Content-Sha256", valid_593124
  var valid_593125 = header.getOrDefault("X-Amz-Date")
  valid_593125 = validateParameter(valid_593125, JString, required = false,
                                 default = nil)
  if valid_593125 != nil:
    section.add "X-Amz-Date", valid_593125
  var valid_593126 = header.getOrDefault("X-Amz-Credential")
  valid_593126 = validateParameter(valid_593126, JString, required = false,
                                 default = nil)
  if valid_593126 != nil:
    section.add "X-Amz-Credential", valid_593126
  var valid_593127 = header.getOrDefault("X-Amz-Security-Token")
  valid_593127 = validateParameter(valid_593127, JString, required = false,
                                 default = nil)
  if valid_593127 != nil:
    section.add "X-Amz-Security-Token", valid_593127
  var valid_593128 = header.getOrDefault("X-Amz-Algorithm")
  valid_593128 = validateParameter(valid_593128, JString, required = false,
                                 default = nil)
  if valid_593128 != nil:
    section.add "X-Amz-Algorithm", valid_593128
  var valid_593129 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593129 = validateParameter(valid_593129, JString, required = false,
                                 default = nil)
  if valid_593129 != nil:
    section.add "X-Amz-SignedHeaders", valid_593129
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593130: Call_DescribeRoute_593117; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an existing route.
  ## 
  let valid = call_593130.validator(path, query, header, formData, body)
  let scheme = call_593130.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593130.url(scheme.get, call_593130.host, call_593130.base,
                         call_593130.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593130, url, valid)

proc call*(call_593131: Call_DescribeRoute_593117; routeName: string;
          meshName: string; virtualRouterName: string): Recallable =
  ## describeRoute
  ## Describes an existing route.
  ##   routeName: string (required)
  ##            : The name of the route to describe.
  ##   meshName: string (required)
  ##           : The name of the service mesh in which the route resides.
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router with which the route is associated.
  var path_593132 = newJObject()
  add(path_593132, "routeName", newJString(routeName))
  add(path_593132, "meshName", newJString(meshName))
  add(path_593132, "virtualRouterName", newJString(virtualRouterName))
  result = call_593131.call(path_593132, nil, nil, nil, nil)

var describeRoute* = Call_DescribeRoute_593117(name: "describeRoute",
    meth: HttpMethod.HttpGet, host: "appmesh.amazonaws.com", route: "/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes/{routeName}",
    validator: validate_DescribeRoute_593118, base: "/", url: url_DescribeRoute_593119,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRoute_593151 = ref object of OpenApiRestCall_592364
proc url_DeleteRoute_593153(protocol: Scheme; host: string; base: string;
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
    segments = @[(kind: ConstantSegment, value: "/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualRouter/"),
               (kind: VariableSegment, value: "virtualRouterName"),
               (kind: ConstantSegment, value: "/routes/"),
               (kind: VariableSegment, value: "routeName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteRoute_593152(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes an existing route.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   routeName: JString (required)
  ##            : The name of the route to delete.
  ##   meshName: JString (required)
  ##           : The name of the service mesh in which to delete the route.
  ##   virtualRouterName: JString (required)
  ##                    : The name of the virtual router in which to delete the route.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `routeName` field"
  var valid_593154 = path.getOrDefault("routeName")
  valid_593154 = validateParameter(valid_593154, JString, required = true,
                                 default = nil)
  if valid_593154 != nil:
    section.add "routeName", valid_593154
  var valid_593155 = path.getOrDefault("meshName")
  valid_593155 = validateParameter(valid_593155, JString, required = true,
                                 default = nil)
  if valid_593155 != nil:
    section.add "meshName", valid_593155
  var valid_593156 = path.getOrDefault("virtualRouterName")
  valid_593156 = validateParameter(valid_593156, JString, required = true,
                                 default = nil)
  if valid_593156 != nil:
    section.add "virtualRouterName", valid_593156
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
  var valid_593157 = header.getOrDefault("X-Amz-Signature")
  valid_593157 = validateParameter(valid_593157, JString, required = false,
                                 default = nil)
  if valid_593157 != nil:
    section.add "X-Amz-Signature", valid_593157
  var valid_593158 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593158 = validateParameter(valid_593158, JString, required = false,
                                 default = nil)
  if valid_593158 != nil:
    section.add "X-Amz-Content-Sha256", valid_593158
  var valid_593159 = header.getOrDefault("X-Amz-Date")
  valid_593159 = validateParameter(valid_593159, JString, required = false,
                                 default = nil)
  if valid_593159 != nil:
    section.add "X-Amz-Date", valid_593159
  var valid_593160 = header.getOrDefault("X-Amz-Credential")
  valid_593160 = validateParameter(valid_593160, JString, required = false,
                                 default = nil)
  if valid_593160 != nil:
    section.add "X-Amz-Credential", valid_593160
  var valid_593161 = header.getOrDefault("X-Amz-Security-Token")
  valid_593161 = validateParameter(valid_593161, JString, required = false,
                                 default = nil)
  if valid_593161 != nil:
    section.add "X-Amz-Security-Token", valid_593161
  var valid_593162 = header.getOrDefault("X-Amz-Algorithm")
  valid_593162 = validateParameter(valid_593162, JString, required = false,
                                 default = nil)
  if valid_593162 != nil:
    section.add "X-Amz-Algorithm", valid_593162
  var valid_593163 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593163 = validateParameter(valid_593163, JString, required = false,
                                 default = nil)
  if valid_593163 != nil:
    section.add "X-Amz-SignedHeaders", valid_593163
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593164: Call_DeleteRoute_593151; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing route.
  ## 
  let valid = call_593164.validator(path, query, header, formData, body)
  let scheme = call_593164.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593164.url(scheme.get, call_593164.host, call_593164.base,
                         call_593164.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593164, url, valid)

proc call*(call_593165: Call_DeleteRoute_593151; routeName: string; meshName: string;
          virtualRouterName: string): Recallable =
  ## deleteRoute
  ## Deletes an existing route.
  ##   routeName: string (required)
  ##            : The name of the route to delete.
  ##   meshName: string (required)
  ##           : The name of the service mesh in which to delete the route.
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router in which to delete the route.
  var path_593166 = newJObject()
  add(path_593166, "routeName", newJString(routeName))
  add(path_593166, "meshName", newJString(meshName))
  add(path_593166, "virtualRouterName", newJString(virtualRouterName))
  result = call_593165.call(path_593166, nil, nil, nil, nil)

var deleteRoute* = Call_DeleteRoute_593151(name: "deleteRoute",
                                        meth: HttpMethod.HttpDelete,
                                        host: "appmesh.amazonaws.com", route: "/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes/{routeName}",
                                        validator: validate_DeleteRoute_593152,
                                        base: "/", url: url_DeleteRoute_593153,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVirtualNode_593182 = ref object of OpenApiRestCall_592364
proc url_UpdateVirtualNode_593184(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  assert "virtualNodeName" in path, "`virtualNodeName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualNodes/"),
               (kind: VariableSegment, value: "virtualNodeName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UpdateVirtualNode_593183(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Updates an existing virtual node in a specified service mesh.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh in which the virtual node resides.
  ##   virtualNodeName: JString (required)
  ##                  : The name of the virtual node to update.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_593185 = path.getOrDefault("meshName")
  valid_593185 = validateParameter(valid_593185, JString, required = true,
                                 default = nil)
  if valid_593185 != nil:
    section.add "meshName", valid_593185
  var valid_593186 = path.getOrDefault("virtualNodeName")
  valid_593186 = validateParameter(valid_593186, JString, required = true,
                                 default = nil)
  if valid_593186 != nil:
    section.add "virtualNodeName", valid_593186
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
  var valid_593187 = header.getOrDefault("X-Amz-Signature")
  valid_593187 = validateParameter(valid_593187, JString, required = false,
                                 default = nil)
  if valid_593187 != nil:
    section.add "X-Amz-Signature", valid_593187
  var valid_593188 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593188 = validateParameter(valid_593188, JString, required = false,
                                 default = nil)
  if valid_593188 != nil:
    section.add "X-Amz-Content-Sha256", valid_593188
  var valid_593189 = header.getOrDefault("X-Amz-Date")
  valid_593189 = validateParameter(valid_593189, JString, required = false,
                                 default = nil)
  if valid_593189 != nil:
    section.add "X-Amz-Date", valid_593189
  var valid_593190 = header.getOrDefault("X-Amz-Credential")
  valid_593190 = validateParameter(valid_593190, JString, required = false,
                                 default = nil)
  if valid_593190 != nil:
    section.add "X-Amz-Credential", valid_593190
  var valid_593191 = header.getOrDefault("X-Amz-Security-Token")
  valid_593191 = validateParameter(valid_593191, JString, required = false,
                                 default = nil)
  if valid_593191 != nil:
    section.add "X-Amz-Security-Token", valid_593191
  var valid_593192 = header.getOrDefault("X-Amz-Algorithm")
  valid_593192 = validateParameter(valid_593192, JString, required = false,
                                 default = nil)
  if valid_593192 != nil:
    section.add "X-Amz-Algorithm", valid_593192
  var valid_593193 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593193 = validateParameter(valid_593193, JString, required = false,
                                 default = nil)
  if valid_593193 != nil:
    section.add "X-Amz-SignedHeaders", valid_593193
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593195: Call_UpdateVirtualNode_593182; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing virtual node in a specified service mesh.
  ## 
  let valid = call_593195.validator(path, query, header, formData, body)
  let scheme = call_593195.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593195.url(scheme.get, call_593195.host, call_593195.base,
                         call_593195.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593195, url, valid)

proc call*(call_593196: Call_UpdateVirtualNode_593182; meshName: string;
          body: JsonNode; virtualNodeName: string): Recallable =
  ## updateVirtualNode
  ## Updates an existing virtual node in a specified service mesh.
  ##   meshName: string (required)
  ##           : The name of the service mesh in which the virtual node resides.
  ##   body: JObject (required)
  ##   virtualNodeName: string (required)
  ##                  : The name of the virtual node to update.
  var path_593197 = newJObject()
  var body_593198 = newJObject()
  add(path_593197, "meshName", newJString(meshName))
  if body != nil:
    body_593198 = body
  add(path_593197, "virtualNodeName", newJString(virtualNodeName))
  result = call_593196.call(path_593197, nil, nil, nil, body_593198)

var updateVirtualNode* = Call_UpdateVirtualNode_593182(name: "updateVirtualNode",
    meth: HttpMethod.HttpPut, host: "appmesh.amazonaws.com",
    route: "/meshes/{meshName}/virtualNodes/{virtualNodeName}",
    validator: validate_UpdateVirtualNode_593183, base: "/",
    url: url_UpdateVirtualNode_593184, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeVirtualNode_593167 = ref object of OpenApiRestCall_592364
proc url_DescribeVirtualNode_593169(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  assert "virtualNodeName" in path, "`virtualNodeName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualNodes/"),
               (kind: VariableSegment, value: "virtualNodeName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DescribeVirtualNode_593168(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Describes an existing virtual node.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh in which the virtual node resides.
  ##   virtualNodeName: JString (required)
  ##                  : The name of the virtual node to describe.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_593170 = path.getOrDefault("meshName")
  valid_593170 = validateParameter(valid_593170, JString, required = true,
                                 default = nil)
  if valid_593170 != nil:
    section.add "meshName", valid_593170
  var valid_593171 = path.getOrDefault("virtualNodeName")
  valid_593171 = validateParameter(valid_593171, JString, required = true,
                                 default = nil)
  if valid_593171 != nil:
    section.add "virtualNodeName", valid_593171
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

proc call*(call_593179: Call_DescribeVirtualNode_593167; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an existing virtual node.
  ## 
  let valid = call_593179.validator(path, query, header, formData, body)
  let scheme = call_593179.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593179.url(scheme.get, call_593179.host, call_593179.base,
                         call_593179.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593179, url, valid)

proc call*(call_593180: Call_DescribeVirtualNode_593167; meshName: string;
          virtualNodeName: string): Recallable =
  ## describeVirtualNode
  ## Describes an existing virtual node.
  ##   meshName: string (required)
  ##           : The name of the service mesh in which the virtual node resides.
  ##   virtualNodeName: string (required)
  ##                  : The name of the virtual node to describe.
  var path_593181 = newJObject()
  add(path_593181, "meshName", newJString(meshName))
  add(path_593181, "virtualNodeName", newJString(virtualNodeName))
  result = call_593180.call(path_593181, nil, nil, nil, nil)

var describeVirtualNode* = Call_DescribeVirtualNode_593167(
    name: "describeVirtualNode", meth: HttpMethod.HttpGet,
    host: "appmesh.amazonaws.com",
    route: "/meshes/{meshName}/virtualNodes/{virtualNodeName}",
    validator: validate_DescribeVirtualNode_593168, base: "/",
    url: url_DescribeVirtualNode_593169, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVirtualNode_593199 = ref object of OpenApiRestCall_592364
proc url_DeleteVirtualNode_593201(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  assert "virtualNodeName" in path, "`virtualNodeName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualNodes/"),
               (kind: VariableSegment, value: "virtualNodeName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteVirtualNode_593200(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Deletes an existing virtual node.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh in which to delete the virtual node.
  ##   virtualNodeName: JString (required)
  ##                  : The name of the virtual node to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_593202 = path.getOrDefault("meshName")
  valid_593202 = validateParameter(valid_593202, JString, required = true,
                                 default = nil)
  if valid_593202 != nil:
    section.add "meshName", valid_593202
  var valid_593203 = path.getOrDefault("virtualNodeName")
  valid_593203 = validateParameter(valid_593203, JString, required = true,
                                 default = nil)
  if valid_593203 != nil:
    section.add "virtualNodeName", valid_593203
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
  var valid_593204 = header.getOrDefault("X-Amz-Signature")
  valid_593204 = validateParameter(valid_593204, JString, required = false,
                                 default = nil)
  if valid_593204 != nil:
    section.add "X-Amz-Signature", valid_593204
  var valid_593205 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593205 = validateParameter(valid_593205, JString, required = false,
                                 default = nil)
  if valid_593205 != nil:
    section.add "X-Amz-Content-Sha256", valid_593205
  var valid_593206 = header.getOrDefault("X-Amz-Date")
  valid_593206 = validateParameter(valid_593206, JString, required = false,
                                 default = nil)
  if valid_593206 != nil:
    section.add "X-Amz-Date", valid_593206
  var valid_593207 = header.getOrDefault("X-Amz-Credential")
  valid_593207 = validateParameter(valid_593207, JString, required = false,
                                 default = nil)
  if valid_593207 != nil:
    section.add "X-Amz-Credential", valid_593207
  var valid_593208 = header.getOrDefault("X-Amz-Security-Token")
  valid_593208 = validateParameter(valid_593208, JString, required = false,
                                 default = nil)
  if valid_593208 != nil:
    section.add "X-Amz-Security-Token", valid_593208
  var valid_593209 = header.getOrDefault("X-Amz-Algorithm")
  valid_593209 = validateParameter(valid_593209, JString, required = false,
                                 default = nil)
  if valid_593209 != nil:
    section.add "X-Amz-Algorithm", valid_593209
  var valid_593210 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593210 = validateParameter(valid_593210, JString, required = false,
                                 default = nil)
  if valid_593210 != nil:
    section.add "X-Amz-SignedHeaders", valid_593210
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593211: Call_DeleteVirtualNode_593199; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing virtual node.
  ## 
  let valid = call_593211.validator(path, query, header, formData, body)
  let scheme = call_593211.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593211.url(scheme.get, call_593211.host, call_593211.base,
                         call_593211.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593211, url, valid)

proc call*(call_593212: Call_DeleteVirtualNode_593199; meshName: string;
          virtualNodeName: string): Recallable =
  ## deleteVirtualNode
  ## Deletes an existing virtual node.
  ##   meshName: string (required)
  ##           : The name of the service mesh in which to delete the virtual node.
  ##   virtualNodeName: string (required)
  ##                  : The name of the virtual node to delete.
  var path_593213 = newJObject()
  add(path_593213, "meshName", newJString(meshName))
  add(path_593213, "virtualNodeName", newJString(virtualNodeName))
  result = call_593212.call(path_593213, nil, nil, nil, nil)

var deleteVirtualNode* = Call_DeleteVirtualNode_593199(name: "deleteVirtualNode",
    meth: HttpMethod.HttpDelete, host: "appmesh.amazonaws.com",
    route: "/meshes/{meshName}/virtualNodes/{virtualNodeName}",
    validator: validate_DeleteVirtualNode_593200, base: "/",
    url: url_DeleteVirtualNode_593201, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVirtualRouter_593229 = ref object of OpenApiRestCall_592364
proc url_UpdateVirtualRouter_593231(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  assert "virtualRouterName" in path,
        "`virtualRouterName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualRouters/"),
               (kind: VariableSegment, value: "virtualRouterName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UpdateVirtualRouter_593230(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Updates an existing virtual router in a specified service mesh.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh in which the virtual router resides.
  ##   virtualRouterName: JString (required)
  ##                    : The name of the virtual router to update.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_593232 = path.getOrDefault("meshName")
  valid_593232 = validateParameter(valid_593232, JString, required = true,
                                 default = nil)
  if valid_593232 != nil:
    section.add "meshName", valid_593232
  var valid_593233 = path.getOrDefault("virtualRouterName")
  valid_593233 = validateParameter(valid_593233, JString, required = true,
                                 default = nil)
  if valid_593233 != nil:
    section.add "virtualRouterName", valid_593233
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
  var valid_593234 = header.getOrDefault("X-Amz-Signature")
  valid_593234 = validateParameter(valid_593234, JString, required = false,
                                 default = nil)
  if valid_593234 != nil:
    section.add "X-Amz-Signature", valid_593234
  var valid_593235 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593235 = validateParameter(valid_593235, JString, required = false,
                                 default = nil)
  if valid_593235 != nil:
    section.add "X-Amz-Content-Sha256", valid_593235
  var valid_593236 = header.getOrDefault("X-Amz-Date")
  valid_593236 = validateParameter(valid_593236, JString, required = false,
                                 default = nil)
  if valid_593236 != nil:
    section.add "X-Amz-Date", valid_593236
  var valid_593237 = header.getOrDefault("X-Amz-Credential")
  valid_593237 = validateParameter(valid_593237, JString, required = false,
                                 default = nil)
  if valid_593237 != nil:
    section.add "X-Amz-Credential", valid_593237
  var valid_593238 = header.getOrDefault("X-Amz-Security-Token")
  valid_593238 = validateParameter(valid_593238, JString, required = false,
                                 default = nil)
  if valid_593238 != nil:
    section.add "X-Amz-Security-Token", valid_593238
  var valid_593239 = header.getOrDefault("X-Amz-Algorithm")
  valid_593239 = validateParameter(valid_593239, JString, required = false,
                                 default = nil)
  if valid_593239 != nil:
    section.add "X-Amz-Algorithm", valid_593239
  var valid_593240 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593240 = validateParameter(valid_593240, JString, required = false,
                                 default = nil)
  if valid_593240 != nil:
    section.add "X-Amz-SignedHeaders", valid_593240
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593242: Call_UpdateVirtualRouter_593229; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing virtual router in a specified service mesh.
  ## 
  let valid = call_593242.validator(path, query, header, formData, body)
  let scheme = call_593242.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593242.url(scheme.get, call_593242.host, call_593242.base,
                         call_593242.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593242, url, valid)

proc call*(call_593243: Call_UpdateVirtualRouter_593229; meshName: string;
          body: JsonNode; virtualRouterName: string): Recallable =
  ## updateVirtualRouter
  ## Updates an existing virtual router in a specified service mesh.
  ##   meshName: string (required)
  ##           : The name of the service mesh in which the virtual router resides.
  ##   body: JObject (required)
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router to update.
  var path_593244 = newJObject()
  var body_593245 = newJObject()
  add(path_593244, "meshName", newJString(meshName))
  if body != nil:
    body_593245 = body
  add(path_593244, "virtualRouterName", newJString(virtualRouterName))
  result = call_593243.call(path_593244, nil, nil, nil, body_593245)

var updateVirtualRouter* = Call_UpdateVirtualRouter_593229(
    name: "updateVirtualRouter", meth: HttpMethod.HttpPut,
    host: "appmesh.amazonaws.com",
    route: "/meshes/{meshName}/virtualRouters/{virtualRouterName}",
    validator: validate_UpdateVirtualRouter_593230, base: "/",
    url: url_UpdateVirtualRouter_593231, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeVirtualRouter_593214 = ref object of OpenApiRestCall_592364
proc url_DescribeVirtualRouter_593216(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  assert "virtualRouterName" in path,
        "`virtualRouterName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualRouters/"),
               (kind: VariableSegment, value: "virtualRouterName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DescribeVirtualRouter_593215(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes an existing virtual router.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh in which the virtual router resides.
  ##   virtualRouterName: JString (required)
  ##                    : The name of the virtual router to describe.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_593217 = path.getOrDefault("meshName")
  valid_593217 = validateParameter(valid_593217, JString, required = true,
                                 default = nil)
  if valid_593217 != nil:
    section.add "meshName", valid_593217
  var valid_593218 = path.getOrDefault("virtualRouterName")
  valid_593218 = validateParameter(valid_593218, JString, required = true,
                                 default = nil)
  if valid_593218 != nil:
    section.add "virtualRouterName", valid_593218
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
  var valid_593219 = header.getOrDefault("X-Amz-Signature")
  valid_593219 = validateParameter(valid_593219, JString, required = false,
                                 default = nil)
  if valid_593219 != nil:
    section.add "X-Amz-Signature", valid_593219
  var valid_593220 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593220 = validateParameter(valid_593220, JString, required = false,
                                 default = nil)
  if valid_593220 != nil:
    section.add "X-Amz-Content-Sha256", valid_593220
  var valid_593221 = header.getOrDefault("X-Amz-Date")
  valid_593221 = validateParameter(valid_593221, JString, required = false,
                                 default = nil)
  if valid_593221 != nil:
    section.add "X-Amz-Date", valid_593221
  var valid_593222 = header.getOrDefault("X-Amz-Credential")
  valid_593222 = validateParameter(valid_593222, JString, required = false,
                                 default = nil)
  if valid_593222 != nil:
    section.add "X-Amz-Credential", valid_593222
  var valid_593223 = header.getOrDefault("X-Amz-Security-Token")
  valid_593223 = validateParameter(valid_593223, JString, required = false,
                                 default = nil)
  if valid_593223 != nil:
    section.add "X-Amz-Security-Token", valid_593223
  var valid_593224 = header.getOrDefault("X-Amz-Algorithm")
  valid_593224 = validateParameter(valid_593224, JString, required = false,
                                 default = nil)
  if valid_593224 != nil:
    section.add "X-Amz-Algorithm", valid_593224
  var valid_593225 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593225 = validateParameter(valid_593225, JString, required = false,
                                 default = nil)
  if valid_593225 != nil:
    section.add "X-Amz-SignedHeaders", valid_593225
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593226: Call_DescribeVirtualRouter_593214; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an existing virtual router.
  ## 
  let valid = call_593226.validator(path, query, header, formData, body)
  let scheme = call_593226.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593226.url(scheme.get, call_593226.host, call_593226.base,
                         call_593226.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593226, url, valid)

proc call*(call_593227: Call_DescribeVirtualRouter_593214; meshName: string;
          virtualRouterName: string): Recallable =
  ## describeVirtualRouter
  ## Describes an existing virtual router.
  ##   meshName: string (required)
  ##           : The name of the service mesh in which the virtual router resides.
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router to describe.
  var path_593228 = newJObject()
  add(path_593228, "meshName", newJString(meshName))
  add(path_593228, "virtualRouterName", newJString(virtualRouterName))
  result = call_593227.call(path_593228, nil, nil, nil, nil)

var describeVirtualRouter* = Call_DescribeVirtualRouter_593214(
    name: "describeVirtualRouter", meth: HttpMethod.HttpGet,
    host: "appmesh.amazonaws.com",
    route: "/meshes/{meshName}/virtualRouters/{virtualRouterName}",
    validator: validate_DescribeVirtualRouter_593215, base: "/",
    url: url_DescribeVirtualRouter_593216, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVirtualRouter_593246 = ref object of OpenApiRestCall_592364
proc url_DeleteVirtualRouter_593248(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  assert "virtualRouterName" in path,
        "`virtualRouterName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualRouters/"),
               (kind: VariableSegment, value: "virtualRouterName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteVirtualRouter_593247(path: JsonNode; query: JsonNode;
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
  ##           : The name of the service mesh in which to delete the virtual router.
  ##   virtualRouterName: JString (required)
  ##                    : The name of the virtual router to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_593249 = path.getOrDefault("meshName")
  valid_593249 = validateParameter(valid_593249, JString, required = true,
                                 default = nil)
  if valid_593249 != nil:
    section.add "meshName", valid_593249
  var valid_593250 = path.getOrDefault("virtualRouterName")
  valid_593250 = validateParameter(valid_593250, JString, required = true,
                                 default = nil)
  if valid_593250 != nil:
    section.add "virtualRouterName", valid_593250
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
  var valid_593251 = header.getOrDefault("X-Amz-Signature")
  valid_593251 = validateParameter(valid_593251, JString, required = false,
                                 default = nil)
  if valid_593251 != nil:
    section.add "X-Amz-Signature", valid_593251
  var valid_593252 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593252 = validateParameter(valid_593252, JString, required = false,
                                 default = nil)
  if valid_593252 != nil:
    section.add "X-Amz-Content-Sha256", valid_593252
  var valid_593253 = header.getOrDefault("X-Amz-Date")
  valid_593253 = validateParameter(valid_593253, JString, required = false,
                                 default = nil)
  if valid_593253 != nil:
    section.add "X-Amz-Date", valid_593253
  var valid_593254 = header.getOrDefault("X-Amz-Credential")
  valid_593254 = validateParameter(valid_593254, JString, required = false,
                                 default = nil)
  if valid_593254 != nil:
    section.add "X-Amz-Credential", valid_593254
  var valid_593255 = header.getOrDefault("X-Amz-Security-Token")
  valid_593255 = validateParameter(valid_593255, JString, required = false,
                                 default = nil)
  if valid_593255 != nil:
    section.add "X-Amz-Security-Token", valid_593255
  var valid_593256 = header.getOrDefault("X-Amz-Algorithm")
  valid_593256 = validateParameter(valid_593256, JString, required = false,
                                 default = nil)
  if valid_593256 != nil:
    section.add "X-Amz-Algorithm", valid_593256
  var valid_593257 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593257 = validateParameter(valid_593257, JString, required = false,
                                 default = nil)
  if valid_593257 != nil:
    section.add "X-Amz-SignedHeaders", valid_593257
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593258: Call_DeleteVirtualRouter_593246; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an existing virtual router.</p>
  ##          <p>You must delete any routes associated with the virtual router before you can delete the
  ##          router itself.</p>
  ## 
  let valid = call_593258.validator(path, query, header, formData, body)
  let scheme = call_593258.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593258.url(scheme.get, call_593258.host, call_593258.base,
                         call_593258.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593258, url, valid)

proc call*(call_593259: Call_DeleteVirtualRouter_593246; meshName: string;
          virtualRouterName: string): Recallable =
  ## deleteVirtualRouter
  ## <p>Deletes an existing virtual router.</p>
  ##          <p>You must delete any routes associated with the virtual router before you can delete the
  ##          router itself.</p>
  ##   meshName: string (required)
  ##           : The name of the service mesh in which to delete the virtual router.
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router to delete.
  var path_593260 = newJObject()
  add(path_593260, "meshName", newJString(meshName))
  add(path_593260, "virtualRouterName", newJString(virtualRouterName))
  result = call_593259.call(path_593260, nil, nil, nil, nil)

var deleteVirtualRouter* = Call_DeleteVirtualRouter_593246(
    name: "deleteVirtualRouter", meth: HttpMethod.HttpDelete,
    host: "appmesh.amazonaws.com",
    route: "/meshes/{meshName}/virtualRouters/{virtualRouterName}",
    validator: validate_DeleteVirtualRouter_593247, base: "/",
    url: url_DeleteVirtualRouter_593248, schemes: {Scheme.Https, Scheme.Http})
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
