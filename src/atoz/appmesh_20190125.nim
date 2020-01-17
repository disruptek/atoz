
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_605589 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_605589](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_605589): Option[Scheme] {.used.} =
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateMesh_606184 = ref object of OpenApiRestCall_605589
proc url_CreateMesh_606186(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateMesh_606185(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606187 = header.getOrDefault("X-Amz-Signature")
  valid_606187 = validateParameter(valid_606187, JString, required = false,
                                 default = nil)
  if valid_606187 != nil:
    section.add "X-Amz-Signature", valid_606187
  var valid_606188 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606188 = validateParameter(valid_606188, JString, required = false,
                                 default = nil)
  if valid_606188 != nil:
    section.add "X-Amz-Content-Sha256", valid_606188
  var valid_606189 = header.getOrDefault("X-Amz-Date")
  valid_606189 = validateParameter(valid_606189, JString, required = false,
                                 default = nil)
  if valid_606189 != nil:
    section.add "X-Amz-Date", valid_606189
  var valid_606190 = header.getOrDefault("X-Amz-Credential")
  valid_606190 = validateParameter(valid_606190, JString, required = false,
                                 default = nil)
  if valid_606190 != nil:
    section.add "X-Amz-Credential", valid_606190
  var valid_606191 = header.getOrDefault("X-Amz-Security-Token")
  valid_606191 = validateParameter(valid_606191, JString, required = false,
                                 default = nil)
  if valid_606191 != nil:
    section.add "X-Amz-Security-Token", valid_606191
  var valid_606192 = header.getOrDefault("X-Amz-Algorithm")
  valid_606192 = validateParameter(valid_606192, JString, required = false,
                                 default = nil)
  if valid_606192 != nil:
    section.add "X-Amz-Algorithm", valid_606192
  var valid_606193 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606193 = validateParameter(valid_606193, JString, required = false,
                                 default = nil)
  if valid_606193 != nil:
    section.add "X-Amz-SignedHeaders", valid_606193
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606195: Call_CreateMesh_606184; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a service mesh. A service mesh is a logical boundary for network traffic between
  ##          the services that reside within it.</p>
  ##          <p>After you create your service mesh, you can create virtual services, virtual nodes,
  ##          virtual routers, and routes to distribute traffic between the applications in your
  ##          mesh.</p>
  ## 
  let valid = call_606195.validator(path, query, header, formData, body)
  let scheme = call_606195.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606195.url(scheme.get, call_606195.host, call_606195.base,
                         call_606195.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606195, url, valid)

proc call*(call_606196: Call_CreateMesh_606184; body: JsonNode): Recallable =
  ## createMesh
  ## <p>Creates a service mesh. A service mesh is a logical boundary for network traffic between
  ##          the services that reside within it.</p>
  ##          <p>After you create your service mesh, you can create virtual services, virtual nodes,
  ##          virtual routers, and routes to distribute traffic between the applications in your
  ##          mesh.</p>
  ##   body: JObject (required)
  var body_606197 = newJObject()
  if body != nil:
    body_606197 = body
  result = call_606196.call(nil, nil, nil, nil, body_606197)

var createMesh* = Call_CreateMesh_606184(name: "createMesh",
                                      meth: HttpMethod.HttpPut,
                                      host: "appmesh.amazonaws.com",
                                      route: "/v20190125/meshes",
                                      validator: validate_CreateMesh_606185,
                                      base: "/", url: url_CreateMesh_606186,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMeshes_605927 = ref object of OpenApiRestCall_605589
proc url_ListMeshes_605929(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListMeshes_605928(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606041 = query.getOrDefault("nextToken")
  valid_606041 = validateParameter(valid_606041, JString, required = false,
                                 default = nil)
  if valid_606041 != nil:
    section.add "nextToken", valid_606041
  var valid_606042 = query.getOrDefault("limit")
  valid_606042 = validateParameter(valid_606042, JInt, required = false, default = nil)
  if valid_606042 != nil:
    section.add "limit", valid_606042
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
  var valid_606043 = header.getOrDefault("X-Amz-Signature")
  valid_606043 = validateParameter(valid_606043, JString, required = false,
                                 default = nil)
  if valid_606043 != nil:
    section.add "X-Amz-Signature", valid_606043
  var valid_606044 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606044 = validateParameter(valid_606044, JString, required = false,
                                 default = nil)
  if valid_606044 != nil:
    section.add "X-Amz-Content-Sha256", valid_606044
  var valid_606045 = header.getOrDefault("X-Amz-Date")
  valid_606045 = validateParameter(valid_606045, JString, required = false,
                                 default = nil)
  if valid_606045 != nil:
    section.add "X-Amz-Date", valid_606045
  var valid_606046 = header.getOrDefault("X-Amz-Credential")
  valid_606046 = validateParameter(valid_606046, JString, required = false,
                                 default = nil)
  if valid_606046 != nil:
    section.add "X-Amz-Credential", valid_606046
  var valid_606047 = header.getOrDefault("X-Amz-Security-Token")
  valid_606047 = validateParameter(valid_606047, JString, required = false,
                                 default = nil)
  if valid_606047 != nil:
    section.add "X-Amz-Security-Token", valid_606047
  var valid_606048 = header.getOrDefault("X-Amz-Algorithm")
  valid_606048 = validateParameter(valid_606048, JString, required = false,
                                 default = nil)
  if valid_606048 != nil:
    section.add "X-Amz-Algorithm", valid_606048
  var valid_606049 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606049 = validateParameter(valid_606049, JString, required = false,
                                 default = nil)
  if valid_606049 != nil:
    section.add "X-Amz-SignedHeaders", valid_606049
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606072: Call_ListMeshes_605927; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of existing service meshes.
  ## 
  let valid = call_606072.validator(path, query, header, formData, body)
  let scheme = call_606072.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606072.url(scheme.get, call_606072.host, call_606072.base,
                         call_606072.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606072, url, valid)

proc call*(call_606143: Call_ListMeshes_605927; nextToken: string = ""; limit: int = 0): Recallable =
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
  var query_606144 = newJObject()
  add(query_606144, "nextToken", newJString(nextToken))
  add(query_606144, "limit", newJInt(limit))
  result = call_606143.call(nil, query_606144, nil, nil, nil)

var listMeshes* = Call_ListMeshes_605927(name: "listMeshes",
                                      meth: HttpMethod.HttpGet,
                                      host: "appmesh.amazonaws.com",
                                      route: "/v20190125/meshes",
                                      validator: validate_ListMeshes_605928,
                                      base: "/", url: url_ListMeshes_605929,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRoute_606230 = ref object of OpenApiRestCall_605589
proc url_CreateRoute_606232(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateRoute_606231(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606233 = path.getOrDefault("meshName")
  valid_606233 = validateParameter(valid_606233, JString, required = true,
                                 default = nil)
  if valid_606233 != nil:
    section.add "meshName", valid_606233
  var valid_606234 = path.getOrDefault("virtualRouterName")
  valid_606234 = validateParameter(valid_606234, JString, required = true,
                                 default = nil)
  if valid_606234 != nil:
    section.add "virtualRouterName", valid_606234
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
  var valid_606235 = header.getOrDefault("X-Amz-Signature")
  valid_606235 = validateParameter(valid_606235, JString, required = false,
                                 default = nil)
  if valid_606235 != nil:
    section.add "X-Amz-Signature", valid_606235
  var valid_606236 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606236 = validateParameter(valid_606236, JString, required = false,
                                 default = nil)
  if valid_606236 != nil:
    section.add "X-Amz-Content-Sha256", valid_606236
  var valid_606237 = header.getOrDefault("X-Amz-Date")
  valid_606237 = validateParameter(valid_606237, JString, required = false,
                                 default = nil)
  if valid_606237 != nil:
    section.add "X-Amz-Date", valid_606237
  var valid_606238 = header.getOrDefault("X-Amz-Credential")
  valid_606238 = validateParameter(valid_606238, JString, required = false,
                                 default = nil)
  if valid_606238 != nil:
    section.add "X-Amz-Credential", valid_606238
  var valid_606239 = header.getOrDefault("X-Amz-Security-Token")
  valid_606239 = validateParameter(valid_606239, JString, required = false,
                                 default = nil)
  if valid_606239 != nil:
    section.add "X-Amz-Security-Token", valid_606239
  var valid_606240 = header.getOrDefault("X-Amz-Algorithm")
  valid_606240 = validateParameter(valid_606240, JString, required = false,
                                 default = nil)
  if valid_606240 != nil:
    section.add "X-Amz-Algorithm", valid_606240
  var valid_606241 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606241 = validateParameter(valid_606241, JString, required = false,
                                 default = nil)
  if valid_606241 != nil:
    section.add "X-Amz-SignedHeaders", valid_606241
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606243: Call_CreateRoute_606230; path: JsonNode; query: JsonNode;
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
  let valid = call_606243.validator(path, query, header, formData, body)
  let scheme = call_606243.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606243.url(scheme.get, call_606243.host, call_606243.base,
                         call_606243.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606243, url, valid)

proc call*(call_606244: Call_CreateRoute_606230; meshName: string; body: JsonNode;
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
  var path_606245 = newJObject()
  var body_606246 = newJObject()
  add(path_606245, "meshName", newJString(meshName))
  if body != nil:
    body_606246 = body
  add(path_606245, "virtualRouterName", newJString(virtualRouterName))
  result = call_606244.call(path_606245, nil, nil, nil, body_606246)

var createRoute* = Call_CreateRoute_606230(name: "createRoute",
                                        meth: HttpMethod.HttpPut,
                                        host: "appmesh.amazonaws.com", route: "/v20190125/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes",
                                        validator: validate_CreateRoute_606231,
                                        base: "/", url: url_CreateRoute_606232,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRoutes_606198 = ref object of OpenApiRestCall_605589
proc url_ListRoutes_606200(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListRoutes_606199(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606215 = path.getOrDefault("meshName")
  valid_606215 = validateParameter(valid_606215, JString, required = true,
                                 default = nil)
  if valid_606215 != nil:
    section.add "meshName", valid_606215
  var valid_606216 = path.getOrDefault("virtualRouterName")
  valid_606216 = validateParameter(valid_606216, JString, required = true,
                                 default = nil)
  if valid_606216 != nil:
    section.add "virtualRouterName", valid_606216
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
  var valid_606217 = query.getOrDefault("nextToken")
  valid_606217 = validateParameter(valid_606217, JString, required = false,
                                 default = nil)
  if valid_606217 != nil:
    section.add "nextToken", valid_606217
  var valid_606218 = query.getOrDefault("limit")
  valid_606218 = validateParameter(valid_606218, JInt, required = false, default = nil)
  if valid_606218 != nil:
    section.add "limit", valid_606218
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
  var valid_606219 = header.getOrDefault("X-Amz-Signature")
  valid_606219 = validateParameter(valid_606219, JString, required = false,
                                 default = nil)
  if valid_606219 != nil:
    section.add "X-Amz-Signature", valid_606219
  var valid_606220 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606220 = validateParameter(valid_606220, JString, required = false,
                                 default = nil)
  if valid_606220 != nil:
    section.add "X-Amz-Content-Sha256", valid_606220
  var valid_606221 = header.getOrDefault("X-Amz-Date")
  valid_606221 = validateParameter(valid_606221, JString, required = false,
                                 default = nil)
  if valid_606221 != nil:
    section.add "X-Amz-Date", valid_606221
  var valid_606222 = header.getOrDefault("X-Amz-Credential")
  valid_606222 = validateParameter(valid_606222, JString, required = false,
                                 default = nil)
  if valid_606222 != nil:
    section.add "X-Amz-Credential", valid_606222
  var valid_606223 = header.getOrDefault("X-Amz-Security-Token")
  valid_606223 = validateParameter(valid_606223, JString, required = false,
                                 default = nil)
  if valid_606223 != nil:
    section.add "X-Amz-Security-Token", valid_606223
  var valid_606224 = header.getOrDefault("X-Amz-Algorithm")
  valid_606224 = validateParameter(valid_606224, JString, required = false,
                                 default = nil)
  if valid_606224 != nil:
    section.add "X-Amz-Algorithm", valid_606224
  var valid_606225 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606225 = validateParameter(valid_606225, JString, required = false,
                                 default = nil)
  if valid_606225 != nil:
    section.add "X-Amz-SignedHeaders", valid_606225
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606226: Call_ListRoutes_606198; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of existing routes in a service mesh.
  ## 
  let valid = call_606226.validator(path, query, header, formData, body)
  let scheme = call_606226.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606226.url(scheme.get, call_606226.host, call_606226.base,
                         call_606226.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606226, url, valid)

proc call*(call_606227: Call_ListRoutes_606198; meshName: string;
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
  var path_606228 = newJObject()
  var query_606229 = newJObject()
  add(query_606229, "nextToken", newJString(nextToken))
  add(query_606229, "limit", newJInt(limit))
  add(path_606228, "meshName", newJString(meshName))
  add(path_606228, "virtualRouterName", newJString(virtualRouterName))
  result = call_606227.call(path_606228, query_606229, nil, nil, nil)

var listRoutes* = Call_ListRoutes_606198(name: "listRoutes",
                                      meth: HttpMethod.HttpGet,
                                      host: "appmesh.amazonaws.com", route: "/v20190125/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes",
                                      validator: validate_ListRoutes_606199,
                                      base: "/", url: url_ListRoutes_606200,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVirtualNode_606264 = ref object of OpenApiRestCall_605589
proc url_CreateVirtualNode_606266(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateVirtualNode_606265(path: JsonNode; query: JsonNode;
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
  var valid_606267 = path.getOrDefault("meshName")
  valid_606267 = validateParameter(valid_606267, JString, required = true,
                                 default = nil)
  if valid_606267 != nil:
    section.add "meshName", valid_606267
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
  var valid_606268 = header.getOrDefault("X-Amz-Signature")
  valid_606268 = validateParameter(valid_606268, JString, required = false,
                                 default = nil)
  if valid_606268 != nil:
    section.add "X-Amz-Signature", valid_606268
  var valid_606269 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606269 = validateParameter(valid_606269, JString, required = false,
                                 default = nil)
  if valid_606269 != nil:
    section.add "X-Amz-Content-Sha256", valid_606269
  var valid_606270 = header.getOrDefault("X-Amz-Date")
  valid_606270 = validateParameter(valid_606270, JString, required = false,
                                 default = nil)
  if valid_606270 != nil:
    section.add "X-Amz-Date", valid_606270
  var valid_606271 = header.getOrDefault("X-Amz-Credential")
  valid_606271 = validateParameter(valid_606271, JString, required = false,
                                 default = nil)
  if valid_606271 != nil:
    section.add "X-Amz-Credential", valid_606271
  var valid_606272 = header.getOrDefault("X-Amz-Security-Token")
  valid_606272 = validateParameter(valid_606272, JString, required = false,
                                 default = nil)
  if valid_606272 != nil:
    section.add "X-Amz-Security-Token", valid_606272
  var valid_606273 = header.getOrDefault("X-Amz-Algorithm")
  valid_606273 = validateParameter(valid_606273, JString, required = false,
                                 default = nil)
  if valid_606273 != nil:
    section.add "X-Amz-Algorithm", valid_606273
  var valid_606274 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606274 = validateParameter(valid_606274, JString, required = false,
                                 default = nil)
  if valid_606274 != nil:
    section.add "X-Amz-SignedHeaders", valid_606274
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606276: Call_CreateVirtualNode_606264; path: JsonNode;
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
  let valid = call_606276.validator(path, query, header, formData, body)
  let scheme = call_606276.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606276.url(scheme.get, call_606276.host, call_606276.base,
                         call_606276.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606276, url, valid)

proc call*(call_606277: Call_CreateVirtualNode_606264; meshName: string;
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
  var path_606278 = newJObject()
  var body_606279 = newJObject()
  add(path_606278, "meshName", newJString(meshName))
  if body != nil:
    body_606279 = body
  result = call_606277.call(path_606278, nil, nil, nil, body_606279)

var createVirtualNode* = Call_CreateVirtualNode_606264(name: "createVirtualNode",
    meth: HttpMethod.HttpPut, host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualNodes",
    validator: validate_CreateVirtualNode_606265, base: "/",
    url: url_CreateVirtualNode_606266, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVirtualNodes_606247 = ref object of OpenApiRestCall_605589
proc url_ListVirtualNodes_606249(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListVirtualNodes_606248(path: JsonNode; query: JsonNode;
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
  var valid_606250 = path.getOrDefault("meshName")
  valid_606250 = validateParameter(valid_606250, JString, required = true,
                                 default = nil)
  if valid_606250 != nil:
    section.add "meshName", valid_606250
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
  var valid_606251 = query.getOrDefault("nextToken")
  valid_606251 = validateParameter(valid_606251, JString, required = false,
                                 default = nil)
  if valid_606251 != nil:
    section.add "nextToken", valid_606251
  var valid_606252 = query.getOrDefault("limit")
  valid_606252 = validateParameter(valid_606252, JInt, required = false, default = nil)
  if valid_606252 != nil:
    section.add "limit", valid_606252
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
  var valid_606253 = header.getOrDefault("X-Amz-Signature")
  valid_606253 = validateParameter(valid_606253, JString, required = false,
                                 default = nil)
  if valid_606253 != nil:
    section.add "X-Amz-Signature", valid_606253
  var valid_606254 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606254 = validateParameter(valid_606254, JString, required = false,
                                 default = nil)
  if valid_606254 != nil:
    section.add "X-Amz-Content-Sha256", valid_606254
  var valid_606255 = header.getOrDefault("X-Amz-Date")
  valid_606255 = validateParameter(valid_606255, JString, required = false,
                                 default = nil)
  if valid_606255 != nil:
    section.add "X-Amz-Date", valid_606255
  var valid_606256 = header.getOrDefault("X-Amz-Credential")
  valid_606256 = validateParameter(valid_606256, JString, required = false,
                                 default = nil)
  if valid_606256 != nil:
    section.add "X-Amz-Credential", valid_606256
  var valid_606257 = header.getOrDefault("X-Amz-Security-Token")
  valid_606257 = validateParameter(valid_606257, JString, required = false,
                                 default = nil)
  if valid_606257 != nil:
    section.add "X-Amz-Security-Token", valid_606257
  var valid_606258 = header.getOrDefault("X-Amz-Algorithm")
  valid_606258 = validateParameter(valid_606258, JString, required = false,
                                 default = nil)
  if valid_606258 != nil:
    section.add "X-Amz-Algorithm", valid_606258
  var valid_606259 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606259 = validateParameter(valid_606259, JString, required = false,
                                 default = nil)
  if valid_606259 != nil:
    section.add "X-Amz-SignedHeaders", valid_606259
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606260: Call_ListVirtualNodes_606247; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of existing virtual nodes.
  ## 
  let valid = call_606260.validator(path, query, header, formData, body)
  let scheme = call_606260.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606260.url(scheme.get, call_606260.host, call_606260.base,
                         call_606260.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606260, url, valid)

proc call*(call_606261: Call_ListVirtualNodes_606247; meshName: string;
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
  var path_606262 = newJObject()
  var query_606263 = newJObject()
  add(query_606263, "nextToken", newJString(nextToken))
  add(query_606263, "limit", newJInt(limit))
  add(path_606262, "meshName", newJString(meshName))
  result = call_606261.call(path_606262, query_606263, nil, nil, nil)

var listVirtualNodes* = Call_ListVirtualNodes_606247(name: "listVirtualNodes",
    meth: HttpMethod.HttpGet, host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualNodes",
    validator: validate_ListVirtualNodes_606248, base: "/",
    url: url_ListVirtualNodes_606249, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVirtualRouter_606297 = ref object of OpenApiRestCall_605589
proc url_CreateVirtualRouter_606299(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateVirtualRouter_606298(path: JsonNode; query: JsonNode;
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
  var valid_606300 = path.getOrDefault("meshName")
  valid_606300 = validateParameter(valid_606300, JString, required = true,
                                 default = nil)
  if valid_606300 != nil:
    section.add "meshName", valid_606300
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
  var valid_606301 = header.getOrDefault("X-Amz-Signature")
  valid_606301 = validateParameter(valid_606301, JString, required = false,
                                 default = nil)
  if valid_606301 != nil:
    section.add "X-Amz-Signature", valid_606301
  var valid_606302 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606302 = validateParameter(valid_606302, JString, required = false,
                                 default = nil)
  if valid_606302 != nil:
    section.add "X-Amz-Content-Sha256", valid_606302
  var valid_606303 = header.getOrDefault("X-Amz-Date")
  valid_606303 = validateParameter(valid_606303, JString, required = false,
                                 default = nil)
  if valid_606303 != nil:
    section.add "X-Amz-Date", valid_606303
  var valid_606304 = header.getOrDefault("X-Amz-Credential")
  valid_606304 = validateParameter(valid_606304, JString, required = false,
                                 default = nil)
  if valid_606304 != nil:
    section.add "X-Amz-Credential", valid_606304
  var valid_606305 = header.getOrDefault("X-Amz-Security-Token")
  valid_606305 = validateParameter(valid_606305, JString, required = false,
                                 default = nil)
  if valid_606305 != nil:
    section.add "X-Amz-Security-Token", valid_606305
  var valid_606306 = header.getOrDefault("X-Amz-Algorithm")
  valid_606306 = validateParameter(valid_606306, JString, required = false,
                                 default = nil)
  if valid_606306 != nil:
    section.add "X-Amz-Algorithm", valid_606306
  var valid_606307 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606307 = validateParameter(valid_606307, JString, required = false,
                                 default = nil)
  if valid_606307 != nil:
    section.add "X-Amz-SignedHeaders", valid_606307
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606309: Call_CreateVirtualRouter_606297; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a virtual router within a service mesh.</p>
  ##          <p>Any inbound traffic that your virtual router expects should be specified as a
  ##             <code>listener</code>. </p>
  ##          <p>Virtual routers handle traffic for one or more virtual services within your mesh. After
  ##          you create your virtual router, create and associate routes for your virtual router that
  ##          direct incoming requests to different virtual nodes.</p>
  ## 
  let valid = call_606309.validator(path, query, header, formData, body)
  let scheme = call_606309.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606309.url(scheme.get, call_606309.host, call_606309.base,
                         call_606309.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606309, url, valid)

proc call*(call_606310: Call_CreateVirtualRouter_606297; meshName: string;
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
  var path_606311 = newJObject()
  var body_606312 = newJObject()
  add(path_606311, "meshName", newJString(meshName))
  if body != nil:
    body_606312 = body
  result = call_606310.call(path_606311, nil, nil, nil, body_606312)

var createVirtualRouter* = Call_CreateVirtualRouter_606297(
    name: "createVirtualRouter", meth: HttpMethod.HttpPut,
    host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualRouters",
    validator: validate_CreateVirtualRouter_606298, base: "/",
    url: url_CreateVirtualRouter_606299, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVirtualRouters_606280 = ref object of OpenApiRestCall_605589
proc url_ListVirtualRouters_606282(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListVirtualRouters_606281(path: JsonNode; query: JsonNode;
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
  var valid_606283 = path.getOrDefault("meshName")
  valid_606283 = validateParameter(valid_606283, JString, required = true,
                                 default = nil)
  if valid_606283 != nil:
    section.add "meshName", valid_606283
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
  var valid_606284 = query.getOrDefault("nextToken")
  valid_606284 = validateParameter(valid_606284, JString, required = false,
                                 default = nil)
  if valid_606284 != nil:
    section.add "nextToken", valid_606284
  var valid_606285 = query.getOrDefault("limit")
  valid_606285 = validateParameter(valid_606285, JInt, required = false, default = nil)
  if valid_606285 != nil:
    section.add "limit", valid_606285
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
  var valid_606286 = header.getOrDefault("X-Amz-Signature")
  valid_606286 = validateParameter(valid_606286, JString, required = false,
                                 default = nil)
  if valid_606286 != nil:
    section.add "X-Amz-Signature", valid_606286
  var valid_606287 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606287 = validateParameter(valid_606287, JString, required = false,
                                 default = nil)
  if valid_606287 != nil:
    section.add "X-Amz-Content-Sha256", valid_606287
  var valid_606288 = header.getOrDefault("X-Amz-Date")
  valid_606288 = validateParameter(valid_606288, JString, required = false,
                                 default = nil)
  if valid_606288 != nil:
    section.add "X-Amz-Date", valid_606288
  var valid_606289 = header.getOrDefault("X-Amz-Credential")
  valid_606289 = validateParameter(valid_606289, JString, required = false,
                                 default = nil)
  if valid_606289 != nil:
    section.add "X-Amz-Credential", valid_606289
  var valid_606290 = header.getOrDefault("X-Amz-Security-Token")
  valid_606290 = validateParameter(valid_606290, JString, required = false,
                                 default = nil)
  if valid_606290 != nil:
    section.add "X-Amz-Security-Token", valid_606290
  var valid_606291 = header.getOrDefault("X-Amz-Algorithm")
  valid_606291 = validateParameter(valid_606291, JString, required = false,
                                 default = nil)
  if valid_606291 != nil:
    section.add "X-Amz-Algorithm", valid_606291
  var valid_606292 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606292 = validateParameter(valid_606292, JString, required = false,
                                 default = nil)
  if valid_606292 != nil:
    section.add "X-Amz-SignedHeaders", valid_606292
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606293: Call_ListVirtualRouters_606280; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of existing virtual routers in a service mesh.
  ## 
  let valid = call_606293.validator(path, query, header, formData, body)
  let scheme = call_606293.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606293.url(scheme.get, call_606293.host, call_606293.base,
                         call_606293.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606293, url, valid)

proc call*(call_606294: Call_ListVirtualRouters_606280; meshName: string;
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
  var path_606295 = newJObject()
  var query_606296 = newJObject()
  add(query_606296, "nextToken", newJString(nextToken))
  add(query_606296, "limit", newJInt(limit))
  add(path_606295, "meshName", newJString(meshName))
  result = call_606294.call(path_606295, query_606296, nil, nil, nil)

var listVirtualRouters* = Call_ListVirtualRouters_606280(
    name: "listVirtualRouters", meth: HttpMethod.HttpGet,
    host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualRouters",
    validator: validate_ListVirtualRouters_606281, base: "/",
    url: url_ListVirtualRouters_606282, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVirtualService_606330 = ref object of OpenApiRestCall_605589
proc url_CreateVirtualService_606332(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateVirtualService_606331(path: JsonNode; query: JsonNode;
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
  var valid_606333 = path.getOrDefault("meshName")
  valid_606333 = validateParameter(valid_606333, JString, required = true,
                                 default = nil)
  if valid_606333 != nil:
    section.add "meshName", valid_606333
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
  var valid_606334 = header.getOrDefault("X-Amz-Signature")
  valid_606334 = validateParameter(valid_606334, JString, required = false,
                                 default = nil)
  if valid_606334 != nil:
    section.add "X-Amz-Signature", valid_606334
  var valid_606335 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606335 = validateParameter(valid_606335, JString, required = false,
                                 default = nil)
  if valid_606335 != nil:
    section.add "X-Amz-Content-Sha256", valid_606335
  var valid_606336 = header.getOrDefault("X-Amz-Date")
  valid_606336 = validateParameter(valid_606336, JString, required = false,
                                 default = nil)
  if valid_606336 != nil:
    section.add "X-Amz-Date", valid_606336
  var valid_606337 = header.getOrDefault("X-Amz-Credential")
  valid_606337 = validateParameter(valid_606337, JString, required = false,
                                 default = nil)
  if valid_606337 != nil:
    section.add "X-Amz-Credential", valid_606337
  var valid_606338 = header.getOrDefault("X-Amz-Security-Token")
  valid_606338 = validateParameter(valid_606338, JString, required = false,
                                 default = nil)
  if valid_606338 != nil:
    section.add "X-Amz-Security-Token", valid_606338
  var valid_606339 = header.getOrDefault("X-Amz-Algorithm")
  valid_606339 = validateParameter(valid_606339, JString, required = false,
                                 default = nil)
  if valid_606339 != nil:
    section.add "X-Amz-Algorithm", valid_606339
  var valid_606340 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606340 = validateParameter(valid_606340, JString, required = false,
                                 default = nil)
  if valid_606340 != nil:
    section.add "X-Amz-SignedHeaders", valid_606340
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606342: Call_CreateVirtualService_606330; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a virtual service within a service mesh.</p>
  ##          <p>A virtual service is an abstraction of a real service that is provided by a virtual node
  ##          directly or indirectly by means of a virtual router. Dependent services call your virtual
  ##          service by its <code>virtualServiceName</code>, and those requests are routed to the
  ##          virtual node or virtual router that is specified as the provider for the virtual
  ##          service.</p>
  ## 
  let valid = call_606342.validator(path, query, header, formData, body)
  let scheme = call_606342.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606342.url(scheme.get, call_606342.host, call_606342.base,
                         call_606342.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606342, url, valid)

proc call*(call_606343: Call_CreateVirtualService_606330; meshName: string;
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
  var path_606344 = newJObject()
  var body_606345 = newJObject()
  add(path_606344, "meshName", newJString(meshName))
  if body != nil:
    body_606345 = body
  result = call_606343.call(path_606344, nil, nil, nil, body_606345)

var createVirtualService* = Call_CreateVirtualService_606330(
    name: "createVirtualService", meth: HttpMethod.HttpPut,
    host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualServices",
    validator: validate_CreateVirtualService_606331, base: "/",
    url: url_CreateVirtualService_606332, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVirtualServices_606313 = ref object of OpenApiRestCall_605589
proc url_ListVirtualServices_606315(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListVirtualServices_606314(path: JsonNode; query: JsonNode;
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
  var valid_606316 = path.getOrDefault("meshName")
  valid_606316 = validateParameter(valid_606316, JString, required = true,
                                 default = nil)
  if valid_606316 != nil:
    section.add "meshName", valid_606316
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
  var valid_606317 = query.getOrDefault("nextToken")
  valid_606317 = validateParameter(valid_606317, JString, required = false,
                                 default = nil)
  if valid_606317 != nil:
    section.add "nextToken", valid_606317
  var valid_606318 = query.getOrDefault("limit")
  valid_606318 = validateParameter(valid_606318, JInt, required = false, default = nil)
  if valid_606318 != nil:
    section.add "limit", valid_606318
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
  var valid_606319 = header.getOrDefault("X-Amz-Signature")
  valid_606319 = validateParameter(valid_606319, JString, required = false,
                                 default = nil)
  if valid_606319 != nil:
    section.add "X-Amz-Signature", valid_606319
  var valid_606320 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606320 = validateParameter(valid_606320, JString, required = false,
                                 default = nil)
  if valid_606320 != nil:
    section.add "X-Amz-Content-Sha256", valid_606320
  var valid_606321 = header.getOrDefault("X-Amz-Date")
  valid_606321 = validateParameter(valid_606321, JString, required = false,
                                 default = nil)
  if valid_606321 != nil:
    section.add "X-Amz-Date", valid_606321
  var valid_606322 = header.getOrDefault("X-Amz-Credential")
  valid_606322 = validateParameter(valid_606322, JString, required = false,
                                 default = nil)
  if valid_606322 != nil:
    section.add "X-Amz-Credential", valid_606322
  var valid_606323 = header.getOrDefault("X-Amz-Security-Token")
  valid_606323 = validateParameter(valid_606323, JString, required = false,
                                 default = nil)
  if valid_606323 != nil:
    section.add "X-Amz-Security-Token", valid_606323
  var valid_606324 = header.getOrDefault("X-Amz-Algorithm")
  valid_606324 = validateParameter(valid_606324, JString, required = false,
                                 default = nil)
  if valid_606324 != nil:
    section.add "X-Amz-Algorithm", valid_606324
  var valid_606325 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606325 = validateParameter(valid_606325, JString, required = false,
                                 default = nil)
  if valid_606325 != nil:
    section.add "X-Amz-SignedHeaders", valid_606325
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606326: Call_ListVirtualServices_606313; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of existing virtual services in a service mesh.
  ## 
  let valid = call_606326.validator(path, query, header, formData, body)
  let scheme = call_606326.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606326.url(scheme.get, call_606326.host, call_606326.base,
                         call_606326.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606326, url, valid)

proc call*(call_606327: Call_ListVirtualServices_606313; meshName: string;
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
  var path_606328 = newJObject()
  var query_606329 = newJObject()
  add(query_606329, "nextToken", newJString(nextToken))
  add(query_606329, "limit", newJInt(limit))
  add(path_606328, "meshName", newJString(meshName))
  result = call_606327.call(path_606328, query_606329, nil, nil, nil)

var listVirtualServices* = Call_ListVirtualServices_606313(
    name: "listVirtualServices", meth: HttpMethod.HttpGet,
    host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualServices",
    validator: validate_ListVirtualServices_606314, base: "/",
    url: url_ListVirtualServices_606315, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMesh_606360 = ref object of OpenApiRestCall_605589
proc url_UpdateMesh_606362(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateMesh_606361(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606363 = path.getOrDefault("meshName")
  valid_606363 = validateParameter(valid_606363, JString, required = true,
                                 default = nil)
  if valid_606363 != nil:
    section.add "meshName", valid_606363
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
  var valid_606364 = header.getOrDefault("X-Amz-Signature")
  valid_606364 = validateParameter(valid_606364, JString, required = false,
                                 default = nil)
  if valid_606364 != nil:
    section.add "X-Amz-Signature", valid_606364
  var valid_606365 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606365 = validateParameter(valid_606365, JString, required = false,
                                 default = nil)
  if valid_606365 != nil:
    section.add "X-Amz-Content-Sha256", valid_606365
  var valid_606366 = header.getOrDefault("X-Amz-Date")
  valid_606366 = validateParameter(valid_606366, JString, required = false,
                                 default = nil)
  if valid_606366 != nil:
    section.add "X-Amz-Date", valid_606366
  var valid_606367 = header.getOrDefault("X-Amz-Credential")
  valid_606367 = validateParameter(valid_606367, JString, required = false,
                                 default = nil)
  if valid_606367 != nil:
    section.add "X-Amz-Credential", valid_606367
  var valid_606368 = header.getOrDefault("X-Amz-Security-Token")
  valid_606368 = validateParameter(valid_606368, JString, required = false,
                                 default = nil)
  if valid_606368 != nil:
    section.add "X-Amz-Security-Token", valid_606368
  var valid_606369 = header.getOrDefault("X-Amz-Algorithm")
  valid_606369 = validateParameter(valid_606369, JString, required = false,
                                 default = nil)
  if valid_606369 != nil:
    section.add "X-Amz-Algorithm", valid_606369
  var valid_606370 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606370 = validateParameter(valid_606370, JString, required = false,
                                 default = nil)
  if valid_606370 != nil:
    section.add "X-Amz-SignedHeaders", valid_606370
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606372: Call_UpdateMesh_606360; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing service mesh.
  ## 
  let valid = call_606372.validator(path, query, header, formData, body)
  let scheme = call_606372.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606372.url(scheme.get, call_606372.host, call_606372.base,
                         call_606372.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606372, url, valid)

proc call*(call_606373: Call_UpdateMesh_606360; meshName: string; body: JsonNode): Recallable =
  ## updateMesh
  ## Updates an existing service mesh.
  ##   meshName: string (required)
  ##           : The name of the service mesh to update.
  ##   body: JObject (required)
  var path_606374 = newJObject()
  var body_606375 = newJObject()
  add(path_606374, "meshName", newJString(meshName))
  if body != nil:
    body_606375 = body
  result = call_606373.call(path_606374, nil, nil, nil, body_606375)

var updateMesh* = Call_UpdateMesh_606360(name: "updateMesh",
                                      meth: HttpMethod.HttpPut,
                                      host: "appmesh.amazonaws.com",
                                      route: "/v20190125/meshes/{meshName}",
                                      validator: validate_UpdateMesh_606361,
                                      base: "/", url: url_UpdateMesh_606362,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMesh_606346 = ref object of OpenApiRestCall_605589
proc url_DescribeMesh_606348(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeMesh_606347(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606349 = path.getOrDefault("meshName")
  valid_606349 = validateParameter(valid_606349, JString, required = true,
                                 default = nil)
  if valid_606349 != nil:
    section.add "meshName", valid_606349
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
  var valid_606350 = header.getOrDefault("X-Amz-Signature")
  valid_606350 = validateParameter(valid_606350, JString, required = false,
                                 default = nil)
  if valid_606350 != nil:
    section.add "X-Amz-Signature", valid_606350
  var valid_606351 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606351 = validateParameter(valid_606351, JString, required = false,
                                 default = nil)
  if valid_606351 != nil:
    section.add "X-Amz-Content-Sha256", valid_606351
  var valid_606352 = header.getOrDefault("X-Amz-Date")
  valid_606352 = validateParameter(valid_606352, JString, required = false,
                                 default = nil)
  if valid_606352 != nil:
    section.add "X-Amz-Date", valid_606352
  var valid_606353 = header.getOrDefault("X-Amz-Credential")
  valid_606353 = validateParameter(valid_606353, JString, required = false,
                                 default = nil)
  if valid_606353 != nil:
    section.add "X-Amz-Credential", valid_606353
  var valid_606354 = header.getOrDefault("X-Amz-Security-Token")
  valid_606354 = validateParameter(valid_606354, JString, required = false,
                                 default = nil)
  if valid_606354 != nil:
    section.add "X-Amz-Security-Token", valid_606354
  var valid_606355 = header.getOrDefault("X-Amz-Algorithm")
  valid_606355 = validateParameter(valid_606355, JString, required = false,
                                 default = nil)
  if valid_606355 != nil:
    section.add "X-Amz-Algorithm", valid_606355
  var valid_606356 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606356 = validateParameter(valid_606356, JString, required = false,
                                 default = nil)
  if valid_606356 != nil:
    section.add "X-Amz-SignedHeaders", valid_606356
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606357: Call_DescribeMesh_606346; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an existing service mesh.
  ## 
  let valid = call_606357.validator(path, query, header, formData, body)
  let scheme = call_606357.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606357.url(scheme.get, call_606357.host, call_606357.base,
                         call_606357.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606357, url, valid)

proc call*(call_606358: Call_DescribeMesh_606346; meshName: string): Recallable =
  ## describeMesh
  ## Describes an existing service mesh.
  ##   meshName: string (required)
  ##           : The name of the service mesh to describe.
  var path_606359 = newJObject()
  add(path_606359, "meshName", newJString(meshName))
  result = call_606358.call(path_606359, nil, nil, nil, nil)

var describeMesh* = Call_DescribeMesh_606346(name: "describeMesh",
    meth: HttpMethod.HttpGet, host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}", validator: validate_DescribeMesh_606347,
    base: "/", url: url_DescribeMesh_606348, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMesh_606376 = ref object of OpenApiRestCall_605589
proc url_DeleteMesh_606378(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteMesh_606377(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606379 = path.getOrDefault("meshName")
  valid_606379 = validateParameter(valid_606379, JString, required = true,
                                 default = nil)
  if valid_606379 != nil:
    section.add "meshName", valid_606379
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
  var valid_606380 = header.getOrDefault("X-Amz-Signature")
  valid_606380 = validateParameter(valid_606380, JString, required = false,
                                 default = nil)
  if valid_606380 != nil:
    section.add "X-Amz-Signature", valid_606380
  var valid_606381 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606381 = validateParameter(valid_606381, JString, required = false,
                                 default = nil)
  if valid_606381 != nil:
    section.add "X-Amz-Content-Sha256", valid_606381
  var valid_606382 = header.getOrDefault("X-Amz-Date")
  valid_606382 = validateParameter(valid_606382, JString, required = false,
                                 default = nil)
  if valid_606382 != nil:
    section.add "X-Amz-Date", valid_606382
  var valid_606383 = header.getOrDefault("X-Amz-Credential")
  valid_606383 = validateParameter(valid_606383, JString, required = false,
                                 default = nil)
  if valid_606383 != nil:
    section.add "X-Amz-Credential", valid_606383
  var valid_606384 = header.getOrDefault("X-Amz-Security-Token")
  valid_606384 = validateParameter(valid_606384, JString, required = false,
                                 default = nil)
  if valid_606384 != nil:
    section.add "X-Amz-Security-Token", valid_606384
  var valid_606385 = header.getOrDefault("X-Amz-Algorithm")
  valid_606385 = validateParameter(valid_606385, JString, required = false,
                                 default = nil)
  if valid_606385 != nil:
    section.add "X-Amz-Algorithm", valid_606385
  var valid_606386 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606386 = validateParameter(valid_606386, JString, required = false,
                                 default = nil)
  if valid_606386 != nil:
    section.add "X-Amz-SignedHeaders", valid_606386
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606387: Call_DeleteMesh_606376; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an existing service mesh.</p>
  ##          <p>You must delete all resources (virtual services, routes, virtual routers, and virtual
  ##          nodes) in the service mesh before you can delete the mesh itself.</p>
  ## 
  let valid = call_606387.validator(path, query, header, formData, body)
  let scheme = call_606387.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606387.url(scheme.get, call_606387.host, call_606387.base,
                         call_606387.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606387, url, valid)

proc call*(call_606388: Call_DeleteMesh_606376; meshName: string): Recallable =
  ## deleteMesh
  ## <p>Deletes an existing service mesh.</p>
  ##          <p>You must delete all resources (virtual services, routes, virtual routers, and virtual
  ##          nodes) in the service mesh before you can delete the mesh itself.</p>
  ##   meshName: string (required)
  ##           : The name of the service mesh to delete.
  var path_606389 = newJObject()
  add(path_606389, "meshName", newJString(meshName))
  result = call_606388.call(path_606389, nil, nil, nil, nil)

var deleteMesh* = Call_DeleteMesh_606376(name: "deleteMesh",
                                      meth: HttpMethod.HttpDelete,
                                      host: "appmesh.amazonaws.com",
                                      route: "/v20190125/meshes/{meshName}",
                                      validator: validate_DeleteMesh_606377,
                                      base: "/", url: url_DeleteMesh_606378,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRoute_606406 = ref object of OpenApiRestCall_605589
proc url_UpdateRoute_606408(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateRoute_606407(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606409 = path.getOrDefault("routeName")
  valid_606409 = validateParameter(valid_606409, JString, required = true,
                                 default = nil)
  if valid_606409 != nil:
    section.add "routeName", valid_606409
  var valid_606410 = path.getOrDefault("meshName")
  valid_606410 = validateParameter(valid_606410, JString, required = true,
                                 default = nil)
  if valid_606410 != nil:
    section.add "meshName", valid_606410
  var valid_606411 = path.getOrDefault("virtualRouterName")
  valid_606411 = validateParameter(valid_606411, JString, required = true,
                                 default = nil)
  if valid_606411 != nil:
    section.add "virtualRouterName", valid_606411
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
  var valid_606412 = header.getOrDefault("X-Amz-Signature")
  valid_606412 = validateParameter(valid_606412, JString, required = false,
                                 default = nil)
  if valid_606412 != nil:
    section.add "X-Amz-Signature", valid_606412
  var valid_606413 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606413 = validateParameter(valid_606413, JString, required = false,
                                 default = nil)
  if valid_606413 != nil:
    section.add "X-Amz-Content-Sha256", valid_606413
  var valid_606414 = header.getOrDefault("X-Amz-Date")
  valid_606414 = validateParameter(valid_606414, JString, required = false,
                                 default = nil)
  if valid_606414 != nil:
    section.add "X-Amz-Date", valid_606414
  var valid_606415 = header.getOrDefault("X-Amz-Credential")
  valid_606415 = validateParameter(valid_606415, JString, required = false,
                                 default = nil)
  if valid_606415 != nil:
    section.add "X-Amz-Credential", valid_606415
  var valid_606416 = header.getOrDefault("X-Amz-Security-Token")
  valid_606416 = validateParameter(valid_606416, JString, required = false,
                                 default = nil)
  if valid_606416 != nil:
    section.add "X-Amz-Security-Token", valid_606416
  var valid_606417 = header.getOrDefault("X-Amz-Algorithm")
  valid_606417 = validateParameter(valid_606417, JString, required = false,
                                 default = nil)
  if valid_606417 != nil:
    section.add "X-Amz-Algorithm", valid_606417
  var valid_606418 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606418 = validateParameter(valid_606418, JString, required = false,
                                 default = nil)
  if valid_606418 != nil:
    section.add "X-Amz-SignedHeaders", valid_606418
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606420: Call_UpdateRoute_606406; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing route for a specified service mesh and virtual router.
  ## 
  let valid = call_606420.validator(path, query, header, formData, body)
  let scheme = call_606420.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606420.url(scheme.get, call_606420.host, call_606420.base,
                         call_606420.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606420, url, valid)

proc call*(call_606421: Call_UpdateRoute_606406; routeName: string; meshName: string;
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
  var path_606422 = newJObject()
  var body_606423 = newJObject()
  add(path_606422, "routeName", newJString(routeName))
  add(path_606422, "meshName", newJString(meshName))
  if body != nil:
    body_606423 = body
  add(path_606422, "virtualRouterName", newJString(virtualRouterName))
  result = call_606421.call(path_606422, nil, nil, nil, body_606423)

var updateRoute* = Call_UpdateRoute_606406(name: "updateRoute",
                                        meth: HttpMethod.HttpPut,
                                        host: "appmesh.amazonaws.com", route: "/v20190125/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes/{routeName}",
                                        validator: validate_UpdateRoute_606407,
                                        base: "/", url: url_UpdateRoute_606408,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRoute_606390 = ref object of OpenApiRestCall_605589
proc url_DescribeRoute_606392(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeRoute_606391(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606393 = path.getOrDefault("routeName")
  valid_606393 = validateParameter(valid_606393, JString, required = true,
                                 default = nil)
  if valid_606393 != nil:
    section.add "routeName", valid_606393
  var valid_606394 = path.getOrDefault("meshName")
  valid_606394 = validateParameter(valid_606394, JString, required = true,
                                 default = nil)
  if valid_606394 != nil:
    section.add "meshName", valid_606394
  var valid_606395 = path.getOrDefault("virtualRouterName")
  valid_606395 = validateParameter(valid_606395, JString, required = true,
                                 default = nil)
  if valid_606395 != nil:
    section.add "virtualRouterName", valid_606395
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
  var valid_606396 = header.getOrDefault("X-Amz-Signature")
  valid_606396 = validateParameter(valid_606396, JString, required = false,
                                 default = nil)
  if valid_606396 != nil:
    section.add "X-Amz-Signature", valid_606396
  var valid_606397 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606397 = validateParameter(valid_606397, JString, required = false,
                                 default = nil)
  if valid_606397 != nil:
    section.add "X-Amz-Content-Sha256", valid_606397
  var valid_606398 = header.getOrDefault("X-Amz-Date")
  valid_606398 = validateParameter(valid_606398, JString, required = false,
                                 default = nil)
  if valid_606398 != nil:
    section.add "X-Amz-Date", valid_606398
  var valid_606399 = header.getOrDefault("X-Amz-Credential")
  valid_606399 = validateParameter(valid_606399, JString, required = false,
                                 default = nil)
  if valid_606399 != nil:
    section.add "X-Amz-Credential", valid_606399
  var valid_606400 = header.getOrDefault("X-Amz-Security-Token")
  valid_606400 = validateParameter(valid_606400, JString, required = false,
                                 default = nil)
  if valid_606400 != nil:
    section.add "X-Amz-Security-Token", valid_606400
  var valid_606401 = header.getOrDefault("X-Amz-Algorithm")
  valid_606401 = validateParameter(valid_606401, JString, required = false,
                                 default = nil)
  if valid_606401 != nil:
    section.add "X-Amz-Algorithm", valid_606401
  var valid_606402 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606402 = validateParameter(valid_606402, JString, required = false,
                                 default = nil)
  if valid_606402 != nil:
    section.add "X-Amz-SignedHeaders", valid_606402
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606403: Call_DescribeRoute_606390; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an existing route.
  ## 
  let valid = call_606403.validator(path, query, header, formData, body)
  let scheme = call_606403.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606403.url(scheme.get, call_606403.host, call_606403.base,
                         call_606403.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606403, url, valid)

proc call*(call_606404: Call_DescribeRoute_606390; routeName: string;
          meshName: string; virtualRouterName: string): Recallable =
  ## describeRoute
  ## Describes an existing route.
  ##   routeName: string (required)
  ##            : The name of the route to describe.
  ##   meshName: string (required)
  ##           : The name of the service mesh that the route resides in.
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router that the route is associated with.
  var path_606405 = newJObject()
  add(path_606405, "routeName", newJString(routeName))
  add(path_606405, "meshName", newJString(meshName))
  add(path_606405, "virtualRouterName", newJString(virtualRouterName))
  result = call_606404.call(path_606405, nil, nil, nil, nil)

var describeRoute* = Call_DescribeRoute_606390(name: "describeRoute",
    meth: HttpMethod.HttpGet, host: "appmesh.amazonaws.com", route: "/v20190125/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes/{routeName}",
    validator: validate_DescribeRoute_606391, base: "/", url: url_DescribeRoute_606392,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRoute_606424 = ref object of OpenApiRestCall_605589
proc url_DeleteRoute_606426(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteRoute_606425(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606427 = path.getOrDefault("routeName")
  valid_606427 = validateParameter(valid_606427, JString, required = true,
                                 default = nil)
  if valid_606427 != nil:
    section.add "routeName", valid_606427
  var valid_606428 = path.getOrDefault("meshName")
  valid_606428 = validateParameter(valid_606428, JString, required = true,
                                 default = nil)
  if valid_606428 != nil:
    section.add "meshName", valid_606428
  var valid_606429 = path.getOrDefault("virtualRouterName")
  valid_606429 = validateParameter(valid_606429, JString, required = true,
                                 default = nil)
  if valid_606429 != nil:
    section.add "virtualRouterName", valid_606429
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
  var valid_606430 = header.getOrDefault("X-Amz-Signature")
  valid_606430 = validateParameter(valid_606430, JString, required = false,
                                 default = nil)
  if valid_606430 != nil:
    section.add "X-Amz-Signature", valid_606430
  var valid_606431 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606431 = validateParameter(valid_606431, JString, required = false,
                                 default = nil)
  if valid_606431 != nil:
    section.add "X-Amz-Content-Sha256", valid_606431
  var valid_606432 = header.getOrDefault("X-Amz-Date")
  valid_606432 = validateParameter(valid_606432, JString, required = false,
                                 default = nil)
  if valid_606432 != nil:
    section.add "X-Amz-Date", valid_606432
  var valid_606433 = header.getOrDefault("X-Amz-Credential")
  valid_606433 = validateParameter(valid_606433, JString, required = false,
                                 default = nil)
  if valid_606433 != nil:
    section.add "X-Amz-Credential", valid_606433
  var valid_606434 = header.getOrDefault("X-Amz-Security-Token")
  valid_606434 = validateParameter(valid_606434, JString, required = false,
                                 default = nil)
  if valid_606434 != nil:
    section.add "X-Amz-Security-Token", valid_606434
  var valid_606435 = header.getOrDefault("X-Amz-Algorithm")
  valid_606435 = validateParameter(valid_606435, JString, required = false,
                                 default = nil)
  if valid_606435 != nil:
    section.add "X-Amz-Algorithm", valid_606435
  var valid_606436 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606436 = validateParameter(valid_606436, JString, required = false,
                                 default = nil)
  if valid_606436 != nil:
    section.add "X-Amz-SignedHeaders", valid_606436
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606437: Call_DeleteRoute_606424; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing route.
  ## 
  let valid = call_606437.validator(path, query, header, formData, body)
  let scheme = call_606437.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606437.url(scheme.get, call_606437.host, call_606437.base,
                         call_606437.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606437, url, valid)

proc call*(call_606438: Call_DeleteRoute_606424; routeName: string; meshName: string;
          virtualRouterName: string): Recallable =
  ## deleteRoute
  ## Deletes an existing route.
  ##   routeName: string (required)
  ##            : The name of the route to delete.
  ##   meshName: string (required)
  ##           : The name of the service mesh to delete the route in.
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router to delete the route in.
  var path_606439 = newJObject()
  add(path_606439, "routeName", newJString(routeName))
  add(path_606439, "meshName", newJString(meshName))
  add(path_606439, "virtualRouterName", newJString(virtualRouterName))
  result = call_606438.call(path_606439, nil, nil, nil, nil)

var deleteRoute* = Call_DeleteRoute_606424(name: "deleteRoute",
                                        meth: HttpMethod.HttpDelete,
                                        host: "appmesh.amazonaws.com", route: "/v20190125/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes/{routeName}",
                                        validator: validate_DeleteRoute_606425,
                                        base: "/", url: url_DeleteRoute_606426,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVirtualNode_606455 = ref object of OpenApiRestCall_605589
proc url_UpdateVirtualNode_606457(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateVirtualNode_606456(path: JsonNode; query: JsonNode;
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
  var valid_606458 = path.getOrDefault("meshName")
  valid_606458 = validateParameter(valid_606458, JString, required = true,
                                 default = nil)
  if valid_606458 != nil:
    section.add "meshName", valid_606458
  var valid_606459 = path.getOrDefault("virtualNodeName")
  valid_606459 = validateParameter(valid_606459, JString, required = true,
                                 default = nil)
  if valid_606459 != nil:
    section.add "virtualNodeName", valid_606459
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
  var valid_606460 = header.getOrDefault("X-Amz-Signature")
  valid_606460 = validateParameter(valid_606460, JString, required = false,
                                 default = nil)
  if valid_606460 != nil:
    section.add "X-Amz-Signature", valid_606460
  var valid_606461 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606461 = validateParameter(valid_606461, JString, required = false,
                                 default = nil)
  if valid_606461 != nil:
    section.add "X-Amz-Content-Sha256", valid_606461
  var valid_606462 = header.getOrDefault("X-Amz-Date")
  valid_606462 = validateParameter(valid_606462, JString, required = false,
                                 default = nil)
  if valid_606462 != nil:
    section.add "X-Amz-Date", valid_606462
  var valid_606463 = header.getOrDefault("X-Amz-Credential")
  valid_606463 = validateParameter(valid_606463, JString, required = false,
                                 default = nil)
  if valid_606463 != nil:
    section.add "X-Amz-Credential", valid_606463
  var valid_606464 = header.getOrDefault("X-Amz-Security-Token")
  valid_606464 = validateParameter(valid_606464, JString, required = false,
                                 default = nil)
  if valid_606464 != nil:
    section.add "X-Amz-Security-Token", valid_606464
  var valid_606465 = header.getOrDefault("X-Amz-Algorithm")
  valid_606465 = validateParameter(valid_606465, JString, required = false,
                                 default = nil)
  if valid_606465 != nil:
    section.add "X-Amz-Algorithm", valid_606465
  var valid_606466 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606466 = validateParameter(valid_606466, JString, required = false,
                                 default = nil)
  if valid_606466 != nil:
    section.add "X-Amz-SignedHeaders", valid_606466
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606468: Call_UpdateVirtualNode_606455; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing virtual node in a specified service mesh.
  ## 
  let valid = call_606468.validator(path, query, header, formData, body)
  let scheme = call_606468.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606468.url(scheme.get, call_606468.host, call_606468.base,
                         call_606468.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606468, url, valid)

proc call*(call_606469: Call_UpdateVirtualNode_606455; meshName: string;
          body: JsonNode; virtualNodeName: string): Recallable =
  ## updateVirtualNode
  ## Updates an existing virtual node in a specified service mesh.
  ##   meshName: string (required)
  ##           : The name of the service mesh that the virtual node resides in.
  ##   body: JObject (required)
  ##   virtualNodeName: string (required)
  ##                  : The name of the virtual node to update.
  var path_606470 = newJObject()
  var body_606471 = newJObject()
  add(path_606470, "meshName", newJString(meshName))
  if body != nil:
    body_606471 = body
  add(path_606470, "virtualNodeName", newJString(virtualNodeName))
  result = call_606469.call(path_606470, nil, nil, nil, body_606471)

var updateVirtualNode* = Call_UpdateVirtualNode_606455(name: "updateVirtualNode",
    meth: HttpMethod.HttpPut, host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualNodes/{virtualNodeName}",
    validator: validate_UpdateVirtualNode_606456, base: "/",
    url: url_UpdateVirtualNode_606457, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeVirtualNode_606440 = ref object of OpenApiRestCall_605589
proc url_DescribeVirtualNode_606442(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeVirtualNode_606441(path: JsonNode; query: JsonNode;
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
  var valid_606443 = path.getOrDefault("meshName")
  valid_606443 = validateParameter(valid_606443, JString, required = true,
                                 default = nil)
  if valid_606443 != nil:
    section.add "meshName", valid_606443
  var valid_606444 = path.getOrDefault("virtualNodeName")
  valid_606444 = validateParameter(valid_606444, JString, required = true,
                                 default = nil)
  if valid_606444 != nil:
    section.add "virtualNodeName", valid_606444
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
  var valid_606445 = header.getOrDefault("X-Amz-Signature")
  valid_606445 = validateParameter(valid_606445, JString, required = false,
                                 default = nil)
  if valid_606445 != nil:
    section.add "X-Amz-Signature", valid_606445
  var valid_606446 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606446 = validateParameter(valid_606446, JString, required = false,
                                 default = nil)
  if valid_606446 != nil:
    section.add "X-Amz-Content-Sha256", valid_606446
  var valid_606447 = header.getOrDefault("X-Amz-Date")
  valid_606447 = validateParameter(valid_606447, JString, required = false,
                                 default = nil)
  if valid_606447 != nil:
    section.add "X-Amz-Date", valid_606447
  var valid_606448 = header.getOrDefault("X-Amz-Credential")
  valid_606448 = validateParameter(valid_606448, JString, required = false,
                                 default = nil)
  if valid_606448 != nil:
    section.add "X-Amz-Credential", valid_606448
  var valid_606449 = header.getOrDefault("X-Amz-Security-Token")
  valid_606449 = validateParameter(valid_606449, JString, required = false,
                                 default = nil)
  if valid_606449 != nil:
    section.add "X-Amz-Security-Token", valid_606449
  var valid_606450 = header.getOrDefault("X-Amz-Algorithm")
  valid_606450 = validateParameter(valid_606450, JString, required = false,
                                 default = nil)
  if valid_606450 != nil:
    section.add "X-Amz-Algorithm", valid_606450
  var valid_606451 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606451 = validateParameter(valid_606451, JString, required = false,
                                 default = nil)
  if valid_606451 != nil:
    section.add "X-Amz-SignedHeaders", valid_606451
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606452: Call_DescribeVirtualNode_606440; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an existing virtual node.
  ## 
  let valid = call_606452.validator(path, query, header, formData, body)
  let scheme = call_606452.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606452.url(scheme.get, call_606452.host, call_606452.base,
                         call_606452.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606452, url, valid)

proc call*(call_606453: Call_DescribeVirtualNode_606440; meshName: string;
          virtualNodeName: string): Recallable =
  ## describeVirtualNode
  ## Describes an existing virtual node.
  ##   meshName: string (required)
  ##           : The name of the service mesh that the virtual node resides in.
  ##   virtualNodeName: string (required)
  ##                  : The name of the virtual node to describe.
  var path_606454 = newJObject()
  add(path_606454, "meshName", newJString(meshName))
  add(path_606454, "virtualNodeName", newJString(virtualNodeName))
  result = call_606453.call(path_606454, nil, nil, nil, nil)

var describeVirtualNode* = Call_DescribeVirtualNode_606440(
    name: "describeVirtualNode", meth: HttpMethod.HttpGet,
    host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualNodes/{virtualNodeName}",
    validator: validate_DescribeVirtualNode_606441, base: "/",
    url: url_DescribeVirtualNode_606442, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVirtualNode_606472 = ref object of OpenApiRestCall_605589
proc url_DeleteVirtualNode_606474(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteVirtualNode_606473(path: JsonNode; query: JsonNode;
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
  var valid_606475 = path.getOrDefault("meshName")
  valid_606475 = validateParameter(valid_606475, JString, required = true,
                                 default = nil)
  if valid_606475 != nil:
    section.add "meshName", valid_606475
  var valid_606476 = path.getOrDefault("virtualNodeName")
  valid_606476 = validateParameter(valid_606476, JString, required = true,
                                 default = nil)
  if valid_606476 != nil:
    section.add "virtualNodeName", valid_606476
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
  var valid_606477 = header.getOrDefault("X-Amz-Signature")
  valid_606477 = validateParameter(valid_606477, JString, required = false,
                                 default = nil)
  if valid_606477 != nil:
    section.add "X-Amz-Signature", valid_606477
  var valid_606478 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606478 = validateParameter(valid_606478, JString, required = false,
                                 default = nil)
  if valid_606478 != nil:
    section.add "X-Amz-Content-Sha256", valid_606478
  var valid_606479 = header.getOrDefault("X-Amz-Date")
  valid_606479 = validateParameter(valid_606479, JString, required = false,
                                 default = nil)
  if valid_606479 != nil:
    section.add "X-Amz-Date", valid_606479
  var valid_606480 = header.getOrDefault("X-Amz-Credential")
  valid_606480 = validateParameter(valid_606480, JString, required = false,
                                 default = nil)
  if valid_606480 != nil:
    section.add "X-Amz-Credential", valid_606480
  var valid_606481 = header.getOrDefault("X-Amz-Security-Token")
  valid_606481 = validateParameter(valid_606481, JString, required = false,
                                 default = nil)
  if valid_606481 != nil:
    section.add "X-Amz-Security-Token", valid_606481
  var valid_606482 = header.getOrDefault("X-Amz-Algorithm")
  valid_606482 = validateParameter(valid_606482, JString, required = false,
                                 default = nil)
  if valid_606482 != nil:
    section.add "X-Amz-Algorithm", valid_606482
  var valid_606483 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606483 = validateParameter(valid_606483, JString, required = false,
                                 default = nil)
  if valid_606483 != nil:
    section.add "X-Amz-SignedHeaders", valid_606483
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606484: Call_DeleteVirtualNode_606472; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an existing virtual node.</p>
  ##          <p>You must delete any virtual services that list a virtual node as a service provider
  ##          before you can delete the virtual node itself.</p>
  ## 
  let valid = call_606484.validator(path, query, header, formData, body)
  let scheme = call_606484.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606484.url(scheme.get, call_606484.host, call_606484.base,
                         call_606484.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606484, url, valid)

proc call*(call_606485: Call_DeleteVirtualNode_606472; meshName: string;
          virtualNodeName: string): Recallable =
  ## deleteVirtualNode
  ## <p>Deletes an existing virtual node.</p>
  ##          <p>You must delete any virtual services that list a virtual node as a service provider
  ##          before you can delete the virtual node itself.</p>
  ##   meshName: string (required)
  ##           : The name of the service mesh to delete the virtual node in.
  ##   virtualNodeName: string (required)
  ##                  : The name of the virtual node to delete.
  var path_606486 = newJObject()
  add(path_606486, "meshName", newJString(meshName))
  add(path_606486, "virtualNodeName", newJString(virtualNodeName))
  result = call_606485.call(path_606486, nil, nil, nil, nil)

var deleteVirtualNode* = Call_DeleteVirtualNode_606472(name: "deleteVirtualNode",
    meth: HttpMethod.HttpDelete, host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualNodes/{virtualNodeName}",
    validator: validate_DeleteVirtualNode_606473, base: "/",
    url: url_DeleteVirtualNode_606474, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVirtualRouter_606502 = ref object of OpenApiRestCall_605589
proc url_UpdateVirtualRouter_606504(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateVirtualRouter_606503(path: JsonNode; query: JsonNode;
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
  var valid_606505 = path.getOrDefault("meshName")
  valid_606505 = validateParameter(valid_606505, JString, required = true,
                                 default = nil)
  if valid_606505 != nil:
    section.add "meshName", valid_606505
  var valid_606506 = path.getOrDefault("virtualRouterName")
  valid_606506 = validateParameter(valid_606506, JString, required = true,
                                 default = nil)
  if valid_606506 != nil:
    section.add "virtualRouterName", valid_606506
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
  var valid_606507 = header.getOrDefault("X-Amz-Signature")
  valid_606507 = validateParameter(valid_606507, JString, required = false,
                                 default = nil)
  if valid_606507 != nil:
    section.add "X-Amz-Signature", valid_606507
  var valid_606508 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606508 = validateParameter(valid_606508, JString, required = false,
                                 default = nil)
  if valid_606508 != nil:
    section.add "X-Amz-Content-Sha256", valid_606508
  var valid_606509 = header.getOrDefault("X-Amz-Date")
  valid_606509 = validateParameter(valid_606509, JString, required = false,
                                 default = nil)
  if valid_606509 != nil:
    section.add "X-Amz-Date", valid_606509
  var valid_606510 = header.getOrDefault("X-Amz-Credential")
  valid_606510 = validateParameter(valid_606510, JString, required = false,
                                 default = nil)
  if valid_606510 != nil:
    section.add "X-Amz-Credential", valid_606510
  var valid_606511 = header.getOrDefault("X-Amz-Security-Token")
  valid_606511 = validateParameter(valid_606511, JString, required = false,
                                 default = nil)
  if valid_606511 != nil:
    section.add "X-Amz-Security-Token", valid_606511
  var valid_606512 = header.getOrDefault("X-Amz-Algorithm")
  valid_606512 = validateParameter(valid_606512, JString, required = false,
                                 default = nil)
  if valid_606512 != nil:
    section.add "X-Amz-Algorithm", valid_606512
  var valid_606513 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606513 = validateParameter(valid_606513, JString, required = false,
                                 default = nil)
  if valid_606513 != nil:
    section.add "X-Amz-SignedHeaders", valid_606513
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606515: Call_UpdateVirtualRouter_606502; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing virtual router in a specified service mesh.
  ## 
  let valid = call_606515.validator(path, query, header, formData, body)
  let scheme = call_606515.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606515.url(scheme.get, call_606515.host, call_606515.base,
                         call_606515.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606515, url, valid)

proc call*(call_606516: Call_UpdateVirtualRouter_606502; meshName: string;
          body: JsonNode; virtualRouterName: string): Recallable =
  ## updateVirtualRouter
  ## Updates an existing virtual router in a specified service mesh.
  ##   meshName: string (required)
  ##           : The name of the service mesh that the virtual router resides in.
  ##   body: JObject (required)
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router to update.
  var path_606517 = newJObject()
  var body_606518 = newJObject()
  add(path_606517, "meshName", newJString(meshName))
  if body != nil:
    body_606518 = body
  add(path_606517, "virtualRouterName", newJString(virtualRouterName))
  result = call_606516.call(path_606517, nil, nil, nil, body_606518)

var updateVirtualRouter* = Call_UpdateVirtualRouter_606502(
    name: "updateVirtualRouter", meth: HttpMethod.HttpPut,
    host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualRouters/{virtualRouterName}",
    validator: validate_UpdateVirtualRouter_606503, base: "/",
    url: url_UpdateVirtualRouter_606504, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeVirtualRouter_606487 = ref object of OpenApiRestCall_605589
proc url_DescribeVirtualRouter_606489(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeVirtualRouter_606488(path: JsonNode; query: JsonNode;
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
  var valid_606490 = path.getOrDefault("meshName")
  valid_606490 = validateParameter(valid_606490, JString, required = true,
                                 default = nil)
  if valid_606490 != nil:
    section.add "meshName", valid_606490
  var valid_606491 = path.getOrDefault("virtualRouterName")
  valid_606491 = validateParameter(valid_606491, JString, required = true,
                                 default = nil)
  if valid_606491 != nil:
    section.add "virtualRouterName", valid_606491
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
  var valid_606492 = header.getOrDefault("X-Amz-Signature")
  valid_606492 = validateParameter(valid_606492, JString, required = false,
                                 default = nil)
  if valid_606492 != nil:
    section.add "X-Amz-Signature", valid_606492
  var valid_606493 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606493 = validateParameter(valid_606493, JString, required = false,
                                 default = nil)
  if valid_606493 != nil:
    section.add "X-Amz-Content-Sha256", valid_606493
  var valid_606494 = header.getOrDefault("X-Amz-Date")
  valid_606494 = validateParameter(valid_606494, JString, required = false,
                                 default = nil)
  if valid_606494 != nil:
    section.add "X-Amz-Date", valid_606494
  var valid_606495 = header.getOrDefault("X-Amz-Credential")
  valid_606495 = validateParameter(valid_606495, JString, required = false,
                                 default = nil)
  if valid_606495 != nil:
    section.add "X-Amz-Credential", valid_606495
  var valid_606496 = header.getOrDefault("X-Amz-Security-Token")
  valid_606496 = validateParameter(valid_606496, JString, required = false,
                                 default = nil)
  if valid_606496 != nil:
    section.add "X-Amz-Security-Token", valid_606496
  var valid_606497 = header.getOrDefault("X-Amz-Algorithm")
  valid_606497 = validateParameter(valid_606497, JString, required = false,
                                 default = nil)
  if valid_606497 != nil:
    section.add "X-Amz-Algorithm", valid_606497
  var valid_606498 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606498 = validateParameter(valid_606498, JString, required = false,
                                 default = nil)
  if valid_606498 != nil:
    section.add "X-Amz-SignedHeaders", valid_606498
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606499: Call_DescribeVirtualRouter_606487; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an existing virtual router.
  ## 
  let valid = call_606499.validator(path, query, header, formData, body)
  let scheme = call_606499.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606499.url(scheme.get, call_606499.host, call_606499.base,
                         call_606499.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606499, url, valid)

proc call*(call_606500: Call_DescribeVirtualRouter_606487; meshName: string;
          virtualRouterName: string): Recallable =
  ## describeVirtualRouter
  ## Describes an existing virtual router.
  ##   meshName: string (required)
  ##           : The name of the service mesh that the virtual router resides in.
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router to describe.
  var path_606501 = newJObject()
  add(path_606501, "meshName", newJString(meshName))
  add(path_606501, "virtualRouterName", newJString(virtualRouterName))
  result = call_606500.call(path_606501, nil, nil, nil, nil)

var describeVirtualRouter* = Call_DescribeVirtualRouter_606487(
    name: "describeVirtualRouter", meth: HttpMethod.HttpGet,
    host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualRouters/{virtualRouterName}",
    validator: validate_DescribeVirtualRouter_606488, base: "/",
    url: url_DescribeVirtualRouter_606489, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVirtualRouter_606519 = ref object of OpenApiRestCall_605589
proc url_DeleteVirtualRouter_606521(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteVirtualRouter_606520(path: JsonNode; query: JsonNode;
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
  var valid_606522 = path.getOrDefault("meshName")
  valid_606522 = validateParameter(valid_606522, JString, required = true,
                                 default = nil)
  if valid_606522 != nil:
    section.add "meshName", valid_606522
  var valid_606523 = path.getOrDefault("virtualRouterName")
  valid_606523 = validateParameter(valid_606523, JString, required = true,
                                 default = nil)
  if valid_606523 != nil:
    section.add "virtualRouterName", valid_606523
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
  var valid_606524 = header.getOrDefault("X-Amz-Signature")
  valid_606524 = validateParameter(valid_606524, JString, required = false,
                                 default = nil)
  if valid_606524 != nil:
    section.add "X-Amz-Signature", valid_606524
  var valid_606525 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606525 = validateParameter(valid_606525, JString, required = false,
                                 default = nil)
  if valid_606525 != nil:
    section.add "X-Amz-Content-Sha256", valid_606525
  var valid_606526 = header.getOrDefault("X-Amz-Date")
  valid_606526 = validateParameter(valid_606526, JString, required = false,
                                 default = nil)
  if valid_606526 != nil:
    section.add "X-Amz-Date", valid_606526
  var valid_606527 = header.getOrDefault("X-Amz-Credential")
  valid_606527 = validateParameter(valid_606527, JString, required = false,
                                 default = nil)
  if valid_606527 != nil:
    section.add "X-Amz-Credential", valid_606527
  var valid_606528 = header.getOrDefault("X-Amz-Security-Token")
  valid_606528 = validateParameter(valid_606528, JString, required = false,
                                 default = nil)
  if valid_606528 != nil:
    section.add "X-Amz-Security-Token", valid_606528
  var valid_606529 = header.getOrDefault("X-Amz-Algorithm")
  valid_606529 = validateParameter(valid_606529, JString, required = false,
                                 default = nil)
  if valid_606529 != nil:
    section.add "X-Amz-Algorithm", valid_606529
  var valid_606530 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606530 = validateParameter(valid_606530, JString, required = false,
                                 default = nil)
  if valid_606530 != nil:
    section.add "X-Amz-SignedHeaders", valid_606530
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606531: Call_DeleteVirtualRouter_606519; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an existing virtual router.</p>
  ##          <p>You must delete any routes associated with the virtual router before you can delete the
  ##          router itself.</p>
  ## 
  let valid = call_606531.validator(path, query, header, formData, body)
  let scheme = call_606531.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606531.url(scheme.get, call_606531.host, call_606531.base,
                         call_606531.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606531, url, valid)

proc call*(call_606532: Call_DeleteVirtualRouter_606519; meshName: string;
          virtualRouterName: string): Recallable =
  ## deleteVirtualRouter
  ## <p>Deletes an existing virtual router.</p>
  ##          <p>You must delete any routes associated with the virtual router before you can delete the
  ##          router itself.</p>
  ##   meshName: string (required)
  ##           : The name of the service mesh to delete the virtual router in.
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router to delete.
  var path_606533 = newJObject()
  add(path_606533, "meshName", newJString(meshName))
  add(path_606533, "virtualRouterName", newJString(virtualRouterName))
  result = call_606532.call(path_606533, nil, nil, nil, nil)

var deleteVirtualRouter* = Call_DeleteVirtualRouter_606519(
    name: "deleteVirtualRouter", meth: HttpMethod.HttpDelete,
    host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualRouters/{virtualRouterName}",
    validator: validate_DeleteVirtualRouter_606520, base: "/",
    url: url_DeleteVirtualRouter_606521, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVirtualService_606549 = ref object of OpenApiRestCall_605589
proc url_UpdateVirtualService_606551(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateVirtualService_606550(path: JsonNode; query: JsonNode;
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
  var valid_606552 = path.getOrDefault("virtualServiceName")
  valid_606552 = validateParameter(valid_606552, JString, required = true,
                                 default = nil)
  if valid_606552 != nil:
    section.add "virtualServiceName", valid_606552
  var valid_606553 = path.getOrDefault("meshName")
  valid_606553 = validateParameter(valid_606553, JString, required = true,
                                 default = nil)
  if valid_606553 != nil:
    section.add "meshName", valid_606553
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
  var valid_606554 = header.getOrDefault("X-Amz-Signature")
  valid_606554 = validateParameter(valid_606554, JString, required = false,
                                 default = nil)
  if valid_606554 != nil:
    section.add "X-Amz-Signature", valid_606554
  var valid_606555 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606555 = validateParameter(valid_606555, JString, required = false,
                                 default = nil)
  if valid_606555 != nil:
    section.add "X-Amz-Content-Sha256", valid_606555
  var valid_606556 = header.getOrDefault("X-Amz-Date")
  valid_606556 = validateParameter(valid_606556, JString, required = false,
                                 default = nil)
  if valid_606556 != nil:
    section.add "X-Amz-Date", valid_606556
  var valid_606557 = header.getOrDefault("X-Amz-Credential")
  valid_606557 = validateParameter(valid_606557, JString, required = false,
                                 default = nil)
  if valid_606557 != nil:
    section.add "X-Amz-Credential", valid_606557
  var valid_606558 = header.getOrDefault("X-Amz-Security-Token")
  valid_606558 = validateParameter(valid_606558, JString, required = false,
                                 default = nil)
  if valid_606558 != nil:
    section.add "X-Amz-Security-Token", valid_606558
  var valid_606559 = header.getOrDefault("X-Amz-Algorithm")
  valid_606559 = validateParameter(valid_606559, JString, required = false,
                                 default = nil)
  if valid_606559 != nil:
    section.add "X-Amz-Algorithm", valid_606559
  var valid_606560 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606560 = validateParameter(valid_606560, JString, required = false,
                                 default = nil)
  if valid_606560 != nil:
    section.add "X-Amz-SignedHeaders", valid_606560
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606562: Call_UpdateVirtualService_606549; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing virtual service in a specified service mesh.
  ## 
  let valid = call_606562.validator(path, query, header, formData, body)
  let scheme = call_606562.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606562.url(scheme.get, call_606562.host, call_606562.base,
                         call_606562.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606562, url, valid)

proc call*(call_606563: Call_UpdateVirtualService_606549;
          virtualServiceName: string; meshName: string; body: JsonNode): Recallable =
  ## updateVirtualService
  ## Updates an existing virtual service in a specified service mesh.
  ##   virtualServiceName: string (required)
  ##                     : The name of the virtual service to update.
  ##   meshName: string (required)
  ##           : The name of the service mesh that the virtual service resides in.
  ##   body: JObject (required)
  var path_606564 = newJObject()
  var body_606565 = newJObject()
  add(path_606564, "virtualServiceName", newJString(virtualServiceName))
  add(path_606564, "meshName", newJString(meshName))
  if body != nil:
    body_606565 = body
  result = call_606563.call(path_606564, nil, nil, nil, body_606565)

var updateVirtualService* = Call_UpdateVirtualService_606549(
    name: "updateVirtualService", meth: HttpMethod.HttpPut,
    host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualServices/{virtualServiceName}",
    validator: validate_UpdateVirtualService_606550, base: "/",
    url: url_UpdateVirtualService_606551, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeVirtualService_606534 = ref object of OpenApiRestCall_605589
proc url_DescribeVirtualService_606536(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeVirtualService_606535(path: JsonNode; query: JsonNode;
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
  var valid_606537 = path.getOrDefault("virtualServiceName")
  valid_606537 = validateParameter(valid_606537, JString, required = true,
                                 default = nil)
  if valid_606537 != nil:
    section.add "virtualServiceName", valid_606537
  var valid_606538 = path.getOrDefault("meshName")
  valid_606538 = validateParameter(valid_606538, JString, required = true,
                                 default = nil)
  if valid_606538 != nil:
    section.add "meshName", valid_606538
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
  var valid_606539 = header.getOrDefault("X-Amz-Signature")
  valid_606539 = validateParameter(valid_606539, JString, required = false,
                                 default = nil)
  if valid_606539 != nil:
    section.add "X-Amz-Signature", valid_606539
  var valid_606540 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606540 = validateParameter(valid_606540, JString, required = false,
                                 default = nil)
  if valid_606540 != nil:
    section.add "X-Amz-Content-Sha256", valid_606540
  var valid_606541 = header.getOrDefault("X-Amz-Date")
  valid_606541 = validateParameter(valid_606541, JString, required = false,
                                 default = nil)
  if valid_606541 != nil:
    section.add "X-Amz-Date", valid_606541
  var valid_606542 = header.getOrDefault("X-Amz-Credential")
  valid_606542 = validateParameter(valid_606542, JString, required = false,
                                 default = nil)
  if valid_606542 != nil:
    section.add "X-Amz-Credential", valid_606542
  var valid_606543 = header.getOrDefault("X-Amz-Security-Token")
  valid_606543 = validateParameter(valid_606543, JString, required = false,
                                 default = nil)
  if valid_606543 != nil:
    section.add "X-Amz-Security-Token", valid_606543
  var valid_606544 = header.getOrDefault("X-Amz-Algorithm")
  valid_606544 = validateParameter(valid_606544, JString, required = false,
                                 default = nil)
  if valid_606544 != nil:
    section.add "X-Amz-Algorithm", valid_606544
  var valid_606545 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606545 = validateParameter(valid_606545, JString, required = false,
                                 default = nil)
  if valid_606545 != nil:
    section.add "X-Amz-SignedHeaders", valid_606545
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606546: Call_DescribeVirtualService_606534; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an existing virtual service.
  ## 
  let valid = call_606546.validator(path, query, header, formData, body)
  let scheme = call_606546.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606546.url(scheme.get, call_606546.host, call_606546.base,
                         call_606546.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606546, url, valid)

proc call*(call_606547: Call_DescribeVirtualService_606534;
          virtualServiceName: string; meshName: string): Recallable =
  ## describeVirtualService
  ## Describes an existing virtual service.
  ##   virtualServiceName: string (required)
  ##                     : The name of the virtual service to describe.
  ##   meshName: string (required)
  ##           : The name of the service mesh that the virtual service resides in.
  var path_606548 = newJObject()
  add(path_606548, "virtualServiceName", newJString(virtualServiceName))
  add(path_606548, "meshName", newJString(meshName))
  result = call_606547.call(path_606548, nil, nil, nil, nil)

var describeVirtualService* = Call_DescribeVirtualService_606534(
    name: "describeVirtualService", meth: HttpMethod.HttpGet,
    host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualServices/{virtualServiceName}",
    validator: validate_DescribeVirtualService_606535, base: "/",
    url: url_DescribeVirtualService_606536, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVirtualService_606566 = ref object of OpenApiRestCall_605589
proc url_DeleteVirtualService_606568(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteVirtualService_606567(path: JsonNode; query: JsonNode;
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
  var valid_606569 = path.getOrDefault("virtualServiceName")
  valid_606569 = validateParameter(valid_606569, JString, required = true,
                                 default = nil)
  if valid_606569 != nil:
    section.add "virtualServiceName", valid_606569
  var valid_606570 = path.getOrDefault("meshName")
  valid_606570 = validateParameter(valid_606570, JString, required = true,
                                 default = nil)
  if valid_606570 != nil:
    section.add "meshName", valid_606570
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
  var valid_606571 = header.getOrDefault("X-Amz-Signature")
  valid_606571 = validateParameter(valid_606571, JString, required = false,
                                 default = nil)
  if valid_606571 != nil:
    section.add "X-Amz-Signature", valid_606571
  var valid_606572 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606572 = validateParameter(valid_606572, JString, required = false,
                                 default = nil)
  if valid_606572 != nil:
    section.add "X-Amz-Content-Sha256", valid_606572
  var valid_606573 = header.getOrDefault("X-Amz-Date")
  valid_606573 = validateParameter(valid_606573, JString, required = false,
                                 default = nil)
  if valid_606573 != nil:
    section.add "X-Amz-Date", valid_606573
  var valid_606574 = header.getOrDefault("X-Amz-Credential")
  valid_606574 = validateParameter(valid_606574, JString, required = false,
                                 default = nil)
  if valid_606574 != nil:
    section.add "X-Amz-Credential", valid_606574
  var valid_606575 = header.getOrDefault("X-Amz-Security-Token")
  valid_606575 = validateParameter(valid_606575, JString, required = false,
                                 default = nil)
  if valid_606575 != nil:
    section.add "X-Amz-Security-Token", valid_606575
  var valid_606576 = header.getOrDefault("X-Amz-Algorithm")
  valid_606576 = validateParameter(valid_606576, JString, required = false,
                                 default = nil)
  if valid_606576 != nil:
    section.add "X-Amz-Algorithm", valid_606576
  var valid_606577 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606577 = validateParameter(valid_606577, JString, required = false,
                                 default = nil)
  if valid_606577 != nil:
    section.add "X-Amz-SignedHeaders", valid_606577
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606578: Call_DeleteVirtualService_606566; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing virtual service.
  ## 
  let valid = call_606578.validator(path, query, header, formData, body)
  let scheme = call_606578.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606578.url(scheme.get, call_606578.host, call_606578.base,
                         call_606578.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606578, url, valid)

proc call*(call_606579: Call_DeleteVirtualService_606566;
          virtualServiceName: string; meshName: string): Recallable =
  ## deleteVirtualService
  ## Deletes an existing virtual service.
  ##   virtualServiceName: string (required)
  ##                     : The name of the virtual service to delete.
  ##   meshName: string (required)
  ##           : The name of the service mesh to delete the virtual service in.
  var path_606580 = newJObject()
  add(path_606580, "virtualServiceName", newJString(virtualServiceName))
  add(path_606580, "meshName", newJString(meshName))
  result = call_606579.call(path_606580, nil, nil, nil, nil)

var deleteVirtualService* = Call_DeleteVirtualService_606566(
    name: "deleteVirtualService", meth: HttpMethod.HttpDelete,
    host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualServices/{virtualServiceName}",
    validator: validate_DeleteVirtualService_606567, base: "/",
    url: url_DeleteVirtualService_606568, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_606581 = ref object of OpenApiRestCall_605589
proc url_ListTagsForResource_606583(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource_606582(path: JsonNode; query: JsonNode;
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
  var valid_606584 = query.getOrDefault("nextToken")
  valid_606584 = validateParameter(valid_606584, JString, required = false,
                                 default = nil)
  if valid_606584 != nil:
    section.add "nextToken", valid_606584
  var valid_606585 = query.getOrDefault("limit")
  valid_606585 = validateParameter(valid_606585, JInt, required = false, default = nil)
  if valid_606585 != nil:
    section.add "limit", valid_606585
  assert query != nil,
        "query argument is necessary due to required `resourceArn` field"
  var valid_606586 = query.getOrDefault("resourceArn")
  valid_606586 = validateParameter(valid_606586, JString, required = true,
                                 default = nil)
  if valid_606586 != nil:
    section.add "resourceArn", valid_606586
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
  var valid_606587 = header.getOrDefault("X-Amz-Signature")
  valid_606587 = validateParameter(valid_606587, JString, required = false,
                                 default = nil)
  if valid_606587 != nil:
    section.add "X-Amz-Signature", valid_606587
  var valid_606588 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606588 = validateParameter(valid_606588, JString, required = false,
                                 default = nil)
  if valid_606588 != nil:
    section.add "X-Amz-Content-Sha256", valid_606588
  var valid_606589 = header.getOrDefault("X-Amz-Date")
  valid_606589 = validateParameter(valid_606589, JString, required = false,
                                 default = nil)
  if valid_606589 != nil:
    section.add "X-Amz-Date", valid_606589
  var valid_606590 = header.getOrDefault("X-Amz-Credential")
  valid_606590 = validateParameter(valid_606590, JString, required = false,
                                 default = nil)
  if valid_606590 != nil:
    section.add "X-Amz-Credential", valid_606590
  var valid_606591 = header.getOrDefault("X-Amz-Security-Token")
  valid_606591 = validateParameter(valid_606591, JString, required = false,
                                 default = nil)
  if valid_606591 != nil:
    section.add "X-Amz-Security-Token", valid_606591
  var valid_606592 = header.getOrDefault("X-Amz-Algorithm")
  valid_606592 = validateParameter(valid_606592, JString, required = false,
                                 default = nil)
  if valid_606592 != nil:
    section.add "X-Amz-Algorithm", valid_606592
  var valid_606593 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606593 = validateParameter(valid_606593, JString, required = false,
                                 default = nil)
  if valid_606593 != nil:
    section.add "X-Amz-SignedHeaders", valid_606593
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606594: Call_ListTagsForResource_606581; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the tags for an App Mesh resource.
  ## 
  let valid = call_606594.validator(path, query, header, formData, body)
  let scheme = call_606594.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606594.url(scheme.get, call_606594.host, call_606594.base,
                         call_606594.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606594, url, valid)

proc call*(call_606595: Call_ListTagsForResource_606581; resourceArn: string;
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
  var query_606596 = newJObject()
  add(query_606596, "nextToken", newJString(nextToken))
  add(query_606596, "limit", newJInt(limit))
  add(query_606596, "resourceArn", newJString(resourceArn))
  result = call_606595.call(nil, query_606596, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_606581(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "appmesh.amazonaws.com", route: "/v20190125/tags#resourceArn",
    validator: validate_ListTagsForResource_606582, base: "/",
    url: url_ListTagsForResource_606583, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_606597 = ref object of OpenApiRestCall_605589
proc url_TagResource_606599(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_606598(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606600 = query.getOrDefault("resourceArn")
  valid_606600 = validateParameter(valid_606600, JString, required = true,
                                 default = nil)
  if valid_606600 != nil:
    section.add "resourceArn", valid_606600
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
  var valid_606601 = header.getOrDefault("X-Amz-Signature")
  valid_606601 = validateParameter(valid_606601, JString, required = false,
                                 default = nil)
  if valid_606601 != nil:
    section.add "X-Amz-Signature", valid_606601
  var valid_606602 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606602 = validateParameter(valid_606602, JString, required = false,
                                 default = nil)
  if valid_606602 != nil:
    section.add "X-Amz-Content-Sha256", valid_606602
  var valid_606603 = header.getOrDefault("X-Amz-Date")
  valid_606603 = validateParameter(valid_606603, JString, required = false,
                                 default = nil)
  if valid_606603 != nil:
    section.add "X-Amz-Date", valid_606603
  var valid_606604 = header.getOrDefault("X-Amz-Credential")
  valid_606604 = validateParameter(valid_606604, JString, required = false,
                                 default = nil)
  if valid_606604 != nil:
    section.add "X-Amz-Credential", valid_606604
  var valid_606605 = header.getOrDefault("X-Amz-Security-Token")
  valid_606605 = validateParameter(valid_606605, JString, required = false,
                                 default = nil)
  if valid_606605 != nil:
    section.add "X-Amz-Security-Token", valid_606605
  var valid_606606 = header.getOrDefault("X-Amz-Algorithm")
  valid_606606 = validateParameter(valid_606606, JString, required = false,
                                 default = nil)
  if valid_606606 != nil:
    section.add "X-Amz-Algorithm", valid_606606
  var valid_606607 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606607 = validateParameter(valid_606607, JString, required = false,
                                 default = nil)
  if valid_606607 != nil:
    section.add "X-Amz-SignedHeaders", valid_606607
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606609: Call_TagResource_606597; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates the specified tags to a resource with the specified <code>resourceArn</code>.
  ##          If existing tags on a resource aren't specified in the request parameters, they aren't
  ##          changed. When a resource is deleted, the tags associated with that resource are also
  ##          deleted.
  ## 
  let valid = call_606609.validator(path, query, header, formData, body)
  let scheme = call_606609.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606609.url(scheme.get, call_606609.host, call_606609.base,
                         call_606609.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606609, url, valid)

proc call*(call_606610: Call_TagResource_606597; body: JsonNode; resourceArn: string): Recallable =
  ## tagResource
  ## Associates the specified tags to a resource with the specified <code>resourceArn</code>.
  ##          If existing tags on a resource aren't specified in the request parameters, they aren't
  ##          changed. When a resource is deleted, the tags associated with that resource are also
  ##          deleted.
  ##   body: JObject (required)
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource to add tags to.
  var query_606611 = newJObject()
  var body_606612 = newJObject()
  if body != nil:
    body_606612 = body
  add(query_606611, "resourceArn", newJString(resourceArn))
  result = call_606610.call(nil, query_606611, nil, nil, body_606612)

var tagResource* = Call_TagResource_606597(name: "tagResource",
                                        meth: HttpMethod.HttpPut,
                                        host: "appmesh.amazonaws.com",
                                        route: "/v20190125/tag#resourceArn",
                                        validator: validate_TagResource_606598,
                                        base: "/", url: url_TagResource_606599,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_606613 = ref object of OpenApiRestCall_605589
proc url_UntagResource_606615(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_606614(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606616 = query.getOrDefault("resourceArn")
  valid_606616 = validateParameter(valid_606616, JString, required = true,
                                 default = nil)
  if valid_606616 != nil:
    section.add "resourceArn", valid_606616
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
  var valid_606617 = header.getOrDefault("X-Amz-Signature")
  valid_606617 = validateParameter(valid_606617, JString, required = false,
                                 default = nil)
  if valid_606617 != nil:
    section.add "X-Amz-Signature", valid_606617
  var valid_606618 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606618 = validateParameter(valid_606618, JString, required = false,
                                 default = nil)
  if valid_606618 != nil:
    section.add "X-Amz-Content-Sha256", valid_606618
  var valid_606619 = header.getOrDefault("X-Amz-Date")
  valid_606619 = validateParameter(valid_606619, JString, required = false,
                                 default = nil)
  if valid_606619 != nil:
    section.add "X-Amz-Date", valid_606619
  var valid_606620 = header.getOrDefault("X-Amz-Credential")
  valid_606620 = validateParameter(valid_606620, JString, required = false,
                                 default = nil)
  if valid_606620 != nil:
    section.add "X-Amz-Credential", valid_606620
  var valid_606621 = header.getOrDefault("X-Amz-Security-Token")
  valid_606621 = validateParameter(valid_606621, JString, required = false,
                                 default = nil)
  if valid_606621 != nil:
    section.add "X-Amz-Security-Token", valid_606621
  var valid_606622 = header.getOrDefault("X-Amz-Algorithm")
  valid_606622 = validateParameter(valid_606622, JString, required = false,
                                 default = nil)
  if valid_606622 != nil:
    section.add "X-Amz-Algorithm", valid_606622
  var valid_606623 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606623 = validateParameter(valid_606623, JString, required = false,
                                 default = nil)
  if valid_606623 != nil:
    section.add "X-Amz-SignedHeaders", valid_606623
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606625: Call_UntagResource_606613; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes specified tags from a resource.
  ## 
  let valid = call_606625.validator(path, query, header, formData, body)
  let scheme = call_606625.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606625.url(scheme.get, call_606625.host, call_606625.base,
                         call_606625.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606625, url, valid)

proc call*(call_606626: Call_UntagResource_606613; body: JsonNode;
          resourceArn: string): Recallable =
  ## untagResource
  ## Deletes specified tags from a resource.
  ##   body: JObject (required)
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource to delete tags from.
  var query_606627 = newJObject()
  var body_606628 = newJObject()
  if body != nil:
    body_606628 = body
  add(query_606627, "resourceArn", newJString(resourceArn))
  result = call_606626.call(nil, query_606627, nil, nil, body_606628)

var untagResource* = Call_UntagResource_606613(name: "untagResource",
    meth: HttpMethod.HttpPut, host: "appmesh.amazonaws.com",
    route: "/v20190125/untag#resourceArn", validator: validate_UntagResource_606614,
    base: "/", url: url_UntagResource_606615, schemes: {Scheme.Https, Scheme.Http})
export
  rest

type
  EnvKind = enum
    BakeIntoBinary = "Baking $1 into the binary",
    FetchFromEnv = "Fetch $1 from the environment"
template sloppyConst(via: EnvKind; name: untyped): untyped =
  import
    macros

  const
    name {.strdefine.}: string = case via
    of BakeIntoBinary:
      getEnv(astToStr(name), "")
    of FetchFromEnv:
      ""
  static :
    let msg = block:
      if name == "":
        "Missing $1 in the environment"
      else:
        $via
    warning msg % [astToStr(name)]

sloppyConst FetchFromEnv, AWS_ACCESS_KEY_ID
sloppyConst FetchFromEnv, AWS_SECRET_ACCESS_KEY
sloppyConst BakeIntoBinary, AWS_REGION
sloppyConst FetchFromEnv, AWS_ACCOUNT_ID
proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", AWS_ACCESS_KEY_ID)
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", AWS_SECRET_ACCESS_KEY)
    region = os.getEnv("AWS_REGION", AWS_REGION)
  assert secret != "", "need $AWS_SECRET_ACCESS_KEY in environment"
  assert access != "", "need $AWS_ACCESS_KEY_ID in environment"
  assert region != "", "need $AWS_REGION in environment"
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  ## the hook is a terrible earworm
  var headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
  let
    body = input.getOrDefault("body")
    text = if body == nil:
      "" elif body.kind == JString:
      body.getStr else:
      $body
  if body != nil and body.kind != JString:
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
